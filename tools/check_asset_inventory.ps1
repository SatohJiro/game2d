param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\assets\asset_manifest.csv')
)

$ErrorActionPreference = 'Stop'
$assetRoot = Join-Path $ProjectPath 'assets'
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Asset manifest not found: $ManifestPath"
}
if (-not (Test-Path -LiteralPath $assetRoot -PathType Container)) {
    throw "Asset directory not found: $assetRoot"
}

$records = @(Import-Csv -LiteralPath $ManifestPath)
$sourceExtensions = @('.png', '.wav', '.ogg')
$sourceAssets = @(Get-ChildItem -LiteralPath $ProjectPath -Recurse -File |
    Where-Object {
        $sourceExtensions -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch '[\\/](\.godot|node_modules|dist|build|docs)[\\/]'
    } |
    Sort-Object FullName)
$errors = [System.Collections.Generic.List[string]]::new()
$manifestPaths = @{}

foreach ($record in $records) {
    if (-not $record.path) {
        $errors.Add('Manifest contains a row without path.')
        continue
    }
    if ($manifestPaths.ContainsKey($record.path)) {
        $errors.Add("Duplicate manifest path: $($record.path)")
        continue
    }
    $manifestPaths[$record.path] = $true

    $absolutePath = Join-Path $ProjectPath $record.path
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        $errors.Add("Manifest file missing on disk: $($record.path)")
        continue
    }
    $file = Get-Item -LiteralPath $absolutePath
    if ([int64]$record.bytes -ne $file.Length) {
        $errors.Add("Size mismatch: $($record.path)")
    }
    $actualHash = (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($record.sha256 -ne $actualHash) {
        $errors.Add("SHA-256 mismatch: $($record.path)")
    }
    if (-not $record.provenance_status -or -not $record.license_spdx) {
        $errors.Add("Missing provenance status/license field: $($record.path)")
    }
}

foreach ($asset in $sourceAssets) {
    $relativePath = $asset.FullName.Substring($ProjectPath.Length + 1).Replace('\', '/')
    if (-not $manifestPaths.ContainsKey($relativePath)) {
        $errors.Add("Source asset is not in manifest: $relativePath")
    }
}

if ($records.Count -ne $sourceAssets.Count) {
    $errors.Add("Manifest/source count mismatch: $($records.Count) rows vs $($sourceAssets.Count) files")
}
if ($errors.Count -gt 0) {
    throw ("Asset inventory check failed:`n- " + ($errors -join "`n- "))
}

$verifiedCount = @($records | Where-Object { $_.provenance_status -eq 'VERIFIED' }).Count
$quarantineCount = $records.Count - $verifiedCount
Write-Host "Asset inventory check passed: $($records.Count) files, $verifiedCount verified, $quarantineCount quarantined/unknown."
