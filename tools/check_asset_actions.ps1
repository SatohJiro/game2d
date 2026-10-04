param(
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $ProjectPath 'docs\assets\asset_manifest.csv'
$actionsPath = Join-Path $ProjectPath 'docs\assets\asset_actions.csv'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Missing manifest: $manifestPath" }
if (-not (Test-Path -LiteralPath $actionsPath -PathType Leaf)) { throw "Missing asset actions: $actionsPath" }

$manifest = @(Import-Csv -LiteralPath $manifestPath)
$actions = @(Import-Csv -LiteralPath $actionsPath)
$errors = [System.Collections.Generic.List[string]]::new()
$actionPaths = @{}
$allowedActions = @('VERIFY_OR_REPLACE', 'HOLD_FOR_REVIEW', 'DEDUP_AFTER_REFERENCE_AUDIT', 'REMOVE_AFTER_REFERENCE_AUDIT')
$allowedPriorities = @('P0', 'P1', 'P2', 'P3')

foreach ($row in $actions) {
    if (-not $row.path) { $errors.Add('Asset action row is missing path.'); continue }
    if ($actionPaths.ContainsKey($row.path)) { $errors.Add("Duplicate asset action path: $($row.path)"); continue }
    $actionPaths[$row.path] = $true
    if ($row.action -notin $allowedActions) { $errors.Add("Invalid action for $($row.path): $($row.action)") }
    if ($row.priority -notin $allowedPriorities) { $errors.Add("Invalid priority for $($row.path): $($row.priority)") }
    if (-not $row.owner -or -not $row.rationale) { $errors.Add("Missing owner/rationale: $($row.path)") }
    if ($row.referenced -eq 'True' -and $row.priority -ne 'P0') { $errors.Add("Runtime asset must remain P0 until verified: $($row.path)") }
}
foreach ($asset in $manifest) {
    if (-not $actionPaths.ContainsKey($asset.path)) { $errors.Add("Manifest asset has no action: $($asset.path)") }
}
if ($actions.Count -ne $manifest.Count) {
    $errors.Add("Action/manifest count mismatch: $($actions.Count) rows vs $($manifest.Count) assets")
}
if ($errors.Count -gt 0) { throw ("Asset action check failed:`n- " + ($errors -join "`n- ")) }

$runtimeCount = @($actions | Where-Object { $_.referenced -eq 'True' }).Count
Write-Host "Asset action check passed: $($actions.Count) classified, $runtimeCount runtime P0."
