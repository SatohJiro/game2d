param(
    [string]$GodotConsole = 'D:\desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe',
    [string]$ProjectPath = (Split-Path -Parent $PSScriptRoot),
    [string]$LogDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build\checks')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $GodotConsole -PathType Leaf)) {
    throw "Godot console executable not found: $GodotConsole"
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'project.godot') -PathType Leaf)) {
    throw "project.godot not found under: $ProjectPath"
}

New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$editorLog = Join-Path $LogDirectory 'headless-editor.log'
$contentLog = Join-Path $LogDirectory 'content-validation.log'
$itemMigrationLog = Join-Path $LogDirectory 'item-migration-validation.log'
$combatLog = Join-Path $LogDirectory 'combat-validation.log'
$playerNeedsLog = Join-Path $LogDirectory 'player-needs-validation.log'
$playerProgressionLog = Join-Path $LogDirectory 'player-progression-validation.log'
$playerLocomotionLog = Join-Path $LogDirectory 'player-locomotion-validation.log'
$playerActionsLog = Join-Path $LogDirectory 'player-actions-validation.log'
$creaturePerceptionLog = Join-Path $LogDirectory 'creature-perception-validation.log'
$creatureDropLog = Join-Path $LogDirectory 'creature-drop-validation.log'
$creatureEcologyLog = Join-Path $LogDirectory 'creature-ecology-validation.log'
$captureLog = Join-Path $LogDirectory 'capture-validation.log'
$petSummonLog = Join-Path $LogDirectory 'pet-summon-validation.log'
$baseProgressionLog = Join-Path $LogDirectory 'base-progression-validation.log'
$saveSchemaLog = Join-Path $LogDirectory 'save-schema-validation.log'
$saveRepositoryLog = Join-Path $LogDirectory 'save-repository-validation.log'
$saveMigrationLog = Join-Path $LogDirectory 'save-migration-validation.log'
$saveCoordinatorLog = Join-Path $LogDirectory 'save-coordinator-validation.log'
$worldBossStateLog = Join-Path $LogDirectory 'world-boss-state-validation.log'
$nightRaidStateLog = Join-Path $LogDirectory 'night-raid-state-validation.log'
$worldChunkLog = Join-Path $LogDirectory 'world-chunk-validation.log'
$ambientSpawnLog = Join-Path $LogDirectory 'ambient-spawn-validation.log'
$chunkDiscoveryLog = Join-Path $LogDirectory 'chunk-discovery-validation.log'
$discoverySaveLog = Join-Path $LogDirectory 'discovery-save-validation.log'
$fastTravelLog = Join-Path $LogDirectory 'fast-travel-validation.log'
$minimapLog = Join-Path $LogDirectory 'minimap-validation.log'
$smokeLog = Join-Path $LogDirectory 'headless-smoke.log'
$failurePattern = 'SCRIPT ERROR|Parse Error|Failed to load script|Cannot open file|Node not found|Invalid get index|^ERROR:'

& (Join-Path $PSScriptRoot 'check_documentation.ps1') -ProjectPath $ProjectPath
& (Join-Path $PSScriptRoot 'check_asset_inventory.ps1') -ProjectPath $ProjectPath
& (Join-Path $PSScriptRoot 'check_asset_actions.ps1') -ProjectPath $ProjectPath

function Invoke-GodotCheck {
    param([string[]]$Arguments, [string]$LogPath, [string]$Name)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $GodotConsole @Arguments 2>&1 | Tee-Object -FilePath $LogPath
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode. See $LogPath"
    }
    if (Select-String -LiteralPath $LogPath -Pattern $failurePattern -Quiet) {
        throw "$Name reported script/resource errors. See $LogPath"
    }
}

Invoke-GodotCheck -Name 'Headless editor load' -LogPath $editorLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--editor', '--quit'
)
Invoke-GodotCheck -Name 'Content registry validation' -LogPath $contentLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_content.gd')
)
Invoke-GodotCheck -Name 'Item migration validation' -LogPath $itemMigrationLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_item_migration.gd')
)
Invoke-GodotCheck -Name 'Combat validation' -LogPath $combatLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_combat.gd')
)
Invoke-GodotCheck -Name 'Player needs validation' -LogPath $playerNeedsLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_player_needs.gd')
)
Invoke-GodotCheck -Name 'Player progression validation' -LogPath $playerProgressionLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_player_progression.gd')
)
Invoke-GodotCheck -Name 'Player locomotion validation' -LogPath $playerLocomotionLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_player_locomotion.gd')
)
Invoke-GodotCheck -Name 'Player action validation' -LogPath $playerActionsLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_player_actions.gd')
)
Invoke-GodotCheck -Name 'Creature perception validation' -LogPath $creaturePerceptionLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_creature_perception.gd')
)
Invoke-GodotCheck -Name 'Creature drop validation' -LogPath $creatureDropLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_creature_drops.gd')
)
Invoke-GodotCheck -Name 'Creature ecology validation' -LogPath $creatureEcologyLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_creature_ecology.gd')
)
Invoke-GodotCheck -Name 'Capture validation' -LogPath $captureLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_capture.gd')
)
Invoke-GodotCheck -Name 'Pet summon validation' -LogPath $petSummonLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_pet_summon.gd')
)
Invoke-GodotCheck -Name 'Base progression validation' -LogPath $baseProgressionLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_base_progression.gd')
)
Invoke-GodotCheck -Name 'Save schema validation' -LogPath $saveSchemaLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_save_schema.gd')
)
Invoke-GodotCheck -Name 'Save repository validation' -LogPath $saveRepositoryLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_save_repository.gd')
)
Invoke-GodotCheck -Name 'Save migration validation' -LogPath $saveMigrationLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_save_migration.gd')
)
Invoke-GodotCheck -Name 'Save coordinator validation' -LogPath $saveCoordinatorLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_save_coordinator.gd')
)
Invoke-GodotCheck -Name 'World boss state validation' -LogPath $worldBossStateLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_world_boss_state.gd')
)
Invoke-GodotCheck -Name 'Night raid state validation' -LogPath $nightRaidStateLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_night_raid_state.gd')
)
Invoke-GodotCheck -Name 'World chunk validation' -LogPath $worldChunkLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_world_chunks.gd')
)
Invoke-GodotCheck -Name 'Ambient spawn validation' -LogPath $ambientSpawnLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_ambient_spawns.gd')
)
Invoke-GodotCheck -Name 'Chunk discovery validation' -LogPath $chunkDiscoveryLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_chunk_discovery.gd')
)
Invoke-GodotCheck -Name 'Discovery save validation' -LogPath $discoverySaveLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_discovery_save.gd')
)
Invoke-GodotCheck -Name 'Fast travel validation' -LogPath $fastTravelLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_fast_travel.gd')
)
Invoke-GodotCheck -Name 'Minimap validation' -LogPath $minimapLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_minimap.gd')
)
$ambientCooldownLog = Join-Path $LogDirectory 'ambient-cooldown-validation.log'
$biomeTableLog = Join-Path $LogDirectory 'biome-table-validation.log'
Invoke-GodotCheck -Name 'Ambient cooldown validation' -LogPath $ambientCooldownLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_ambient_cooldown.gd')
)
Invoke-GodotCheck -Name 'Biome table validation' -LogPath $biomeTableLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_biome_spawn_table.gd')
)
$staticContentLog = Join-Path $LogDirectory 'static-content-validation.log'
$hudViewModelLog = Join-Path $LogDirectory 'hud-viewmodel-validation.log'
$modalViewModelLog = Join-Path $LogDirectory 'modal-viewmodel-validation.log'
Invoke-GodotCheck -Name 'Static content validation' -LogPath $staticContentLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_static_content.gd')
)
Invoke-GodotCheck -Name 'HUD ViewModel validation' -LogPath $hudViewModelLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_hud_viewmodel.gd')
)
Invoke-GodotCheck -Name 'Modal ViewModel validation' -LogPath $modalViewModelLog -Arguments @(
	'--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\validate_modal_viewmodel.gd')
)
Invoke-GodotCheck -Name 'Main scene smoke' -LogPath $smokeLog -Arguments @(
    '--headless', '--path', $ProjectPath, '--script', (Join-Path $ProjectPath 'tools\smoke_main.gd')
)

Write-Host "Godot checks passed. Logs: $LogDirectory"
