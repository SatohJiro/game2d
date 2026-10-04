param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\assets')
)

$ErrorActionPreference = 'Stop'
$assetRoot = Join-Path $ProjectPath 'assets'
if (-not (Test-Path -LiteralPath $assetRoot -PathType Container)) {
    throw "Asset directory not found: $assetRoot"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$provenancePath = Join-Path $OutputDirectory 'provenance_overrides.csv'
$provenanceLookup = @{}
if (Test-Path -LiteralPath $provenancePath -PathType Leaf) {
    foreach ($entry in (Import-Csv -LiteralPath $provenancePath)) {
        if ($entry.path) {
            $provenanceLookup[$entry.path.Replace('\', '/')] = $entry
        }
    }
}

$referenceFiles = @()
$referenceFiles += Get-ChildItem -LiteralPath (Join-Path $ProjectPath 'scripts') -Recurse -File -Filter '*.gd'
$referenceFiles += Get-ChildItem -LiteralPath (Join-Path $ProjectPath 'scenes') -Recurse -File -Filter '*.tscn'
$referenceFiles += Get-Item -LiteralPath (Join-Path $ProjectPath 'project.godot')
$referenceText = ($referenceFiles | ForEach-Object {
    Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
}) -join "`n"

$sourceExtensions = @('.png', '.wav', '.ogg')
$sourceAssets = Get-ChildItem -LiteralPath $ProjectPath -Recurse -File |
    Where-Object {
        $candidateRelativePath = $_.FullName.Substring($ProjectPath.Length + 1).Replace('\', '/')
        $candidateTopDirectory = $candidateRelativePath.Split('/')[0]
        $sourceExtensions -contains $_.Extension.ToLowerInvariant() -and
        $candidateTopDirectory -notin @('.godot', 'node_modules', 'dist', 'build', 'docs')
    } |
    Sort-Object FullName

$records = @(foreach ($asset in $sourceAssets) {
    $relativePath = $asset.FullName.Substring($ProjectPath.Length + 1).Replace('\', '/')
    $resourcePath = "res://$relativePath"
    $pathParts = $relativePath.Split('/')
    $category = if ($pathParts.Count -gt 2 -and $pathParts[0] -eq 'assets') { $pathParts[1] } else { '_root' }
    $provenance = if ($provenanceLookup.ContainsKey($relativePath)) { $provenanceLookup[$relativePath] } else { $null }
    $kind = switch ($asset.Extension.ToLowerInvariant()) {
        '.png' { 'texture' }
        '.wav' { 'sfx' }
        '.ogg' { 'music' }
        default { 'other' }
    }

    [PSCustomObject][ordered]@{
        path = $relativePath
        kind = $kind
        category = $category
        bytes = $asset.Length
        sha256 = (Get-FileHash -LiteralPath $asset.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        referenced = $referenceText.Contains($resourcePath)
        provenance_status = if ($provenance -and $provenance.provenance_status) { $provenance.provenance_status } else { 'QUARANTINE' }
        license_spdx = if ($provenance -and $provenance.license_spdx) { $provenance.license_spdx } else { 'UNKNOWN' }
        author = if ($provenance) { $provenance.author } else { '' }
        source_page = if ($provenance) { $provenance.source_page } else { '' }
        intended_use = if ($provenance -and $provenance.intended_use) { $provenance.intended_use } elseif ($referenceText.Contains($resourcePath)) { 'current-runtime' } else { 'unassigned' }
        notes = if ($provenance -and $provenance.notes) { $provenance.notes } else { 'Existing file; origin and redistribution rights not yet verified.' }
    }
})

$duplicateLookup = @{}
$duplicateGroups = @($records | Group-Object sha256 | Where-Object { $_.Count -gt 1 })
foreach ($group in $duplicateGroups) {
    $groupId = "dup-$($group.Name.Substring(0, 12))"
    foreach ($record in $group.Group) {
        $duplicateLookup[$record.path] = $groupId
    }
}

$manifestRecords = @(foreach ($record in $records) {
    [PSCustomObject][ordered]@{
        path = $record.path
        kind = $record.kind
        category = $record.category
        bytes = $record.bytes
        sha256 = $record.sha256
        duplicate_group = if ($duplicateLookup.ContainsKey($record.path)) { $duplicateLookup[$record.path] } else { '' }
        referenced = $record.referenced
        provenance_status = $record.provenance_status
        license_spdx = $record.license_spdx
        author = $record.author
        source_page = $record.source_page
        intended_use = $record.intended_use
        notes = $record.notes
    }
})

$csvPath = Join-Path $OutputDirectory 'asset_manifest.csv'
$jsonPath = Join-Path $OutputDirectory 'asset_manifest.json'
$summaryPath = Join-Path $OutputDirectory 'INVENTORY.md'
$manifestRecords | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
$manifestRecords | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$referencedCount = @($manifestRecords | Where-Object referenced).Count
$unreferencedCount = $manifestRecords.Count - $referencedCount
$verifiedCount = @($manifestRecords | Where-Object { $_.provenance_status -eq 'VERIFIED' }).Count
$quarantineCount = @($manifestRecords | Where-Object { $_.provenance_status -ne 'VERIFIED' }).Count
$duplicateFileCount = @($duplicateGroups | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
if ($null -eq $duplicateFileCount) { $duplicateFileCount = 0 }
$categoryRows = $manifestRecords | Group-Object category | Sort-Object Name

$lines = @(
    '# Asset inventory',
    '',
    '> Generated by `tools/generate_asset_inventory.ps1`. Do not hand-edit the CSV/JSON counts; update provenance fields through a reviewed workflow and regenerate derived reports.',
    '',
    "Generated: $((Get-Date).ToString('yyyy-MM-dd'))",
    '',
    '## Gate status',
    '',
    "- Source assets: $($manifestRecords.Count)",
    "- Referenced by current scripts/scenes: $referencedCount",
    "- Unreferenced: $unreferencedCount",
    "- Duplicate hash groups: $($duplicateGroups.Count) ($duplicateFileCount files)",
    "- Verified provenance: $verifiedCount",
    "- Quarantined/unknown: $quarantineCount",
    '',
    'All current assets remain in place so the playable baseline is preserved. `QUARANTINE` means the file can support local development but must not be included in a distributable build until its source and license are verified or it is replaced.',
    '',
    '## By category',
    '',
    '| Category | Files | Referenced | Bytes |',
    '|---|---:|---:|---:|'
)
foreach ($categoryRow in $categoryRows) {
    $categoryReferenced = @($categoryRow.Group | Where-Object referenced).Count
    $categoryBytes = ($categoryRow.Group | Measure-Object -Property bytes -Sum).Sum
    $lines += "| $($categoryRow.Name) | $($categoryRow.Count) | $categoryReferenced | $categoryBytes |"
}

$lines += @('', '## Exact duplicate groups', '')
if ($duplicateGroups.Count -eq 0) {
    $lines += 'No byte-identical source assets were found.'
} else {
    foreach ($group in $duplicateGroups) {
        $lines += "### dup-$($group.Name.Substring(0, 12))"
        $lines += ''
        foreach ($record in ($group.Group | Sort-Object path)) {
            $lines += ('- `' + $record.path + '`')
        }
        $lines += ''
    }
}

$lines += @(
    '## Files and ownership',
    '',
    '- `asset_manifest.csv`: review-friendly source inventory.',
    '- `asset_manifest.json`: machine-readable copy for later validators and build gates.',
    '- `provenance_overrides.csv`: curated source/license data preserved across regeneration.',
    '- `docs/ASSET_PLAN.md`: admission policy and candidate packages.',
    '- No asset was moved, deleted, downloaded or relicensed by this inventory step.'
)
$lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host "Asset inventory generated: $($manifestRecords.Count) source files, $referencedCount referenced, $($duplicateGroups.Count) duplicate groups."
