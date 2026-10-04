param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$requiredFiles = @(
    'AGENTS.md',
    'README.md',
    'docs/INDEX.md',
    'docs/CHECKPOINT.md',
    'docs/MAJOR_UPDATE_PLAN.md',
    'docs/ASSET_PLAN.md',
    'docs/architecture/MODULES.md',
    'docs/gameplay/FEATURES.md',
    'docs/roadmap/IMPLEMENTATION_PHASES.md',
    'docs/process/DOCUMENTATION_STANDARD.md',
    'docs/process/WORK_PACKAGE_TEMPLATE.md',
    'docs/assets/INVENTORY.md',
    'docs/assets/asset_manifest.csv',
    'docs/assets/asset_manifest.json',
    'docs/assets/provenance_overrides.csv'
)

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($relativePath in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath $relativePath) -PathType Leaf)) {
        $errors.Add("Required documentation file is missing: $relativePath")
    }
}

$markdownFiles = @(Get-ChildItem -LiteralPath $ProjectPath -Recurse -File -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/](\.godot|node_modules|dist|build)[\\/]' })
$linkPattern = [regex]'\[[^\]]+\]\((?<target>[^)]+)\)'
foreach ($markdown in $markdownFiles) {
    $content = Get-Content -LiteralPath $markdown.FullName -Raw -Encoding UTF8
    foreach ($match in $linkPattern.Matches($content)) {
        $target = $match.Groups['target'].Value.Trim()
        if ($target -match '^(https?://|#|mailto:)' -or $target.StartsWith('<')) {
            continue
        }
        $pathPart = $target.Split('#')[0]
        if (-not $pathPart) { continue }
        $resolved = Join-Path $markdown.DirectoryName $pathPart
        if (-not (Test-Path -LiteralPath $resolved)) {
            $relativeMarkdown = $markdown.FullName.Substring($ProjectPath.Length + 1).Replace('\', '/')
            $errors.Add("Broken relative link in ${relativeMarkdown}: $target")
        }
    }
}

if ($errors.Count -gt 0) {
    throw ("Documentation check failed:`n- " + ($errors -join "`n- "))
}

Write-Host "Documentation check passed: $($requiredFiles.Count) required files, $($markdownFiles.Count) Markdown files scanned."
