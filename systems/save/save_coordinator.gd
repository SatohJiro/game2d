class_name SaveCoordinator
extends RefCounted

const SnapshotAdapter = preload("res://systems/save/save_snapshot_adapter.gd")
const Repository = preload("res://systems/save/save_repository.gd")
const RepositoryResult = preload("res://systems/save/save_repository_result.gd")
const MigrationRegistry = preload("res://systems/save/save_migration_registry.gd")
const ApplyAdapter = preload("res://systems/save/save_apply_adapter.gd")
const CoordinatorResult = preload("res://systems/save/save_coordinator_result.gd")

var repository: RefCounted
var migration_registry: RefCounted


func _init(primary_path: String, p_migration_registry: RefCounted = null) -> void:
	repository = Repository.new(primary_path)
	migration_registry = p_migration_registry if p_migration_registry != null else MigrationRegistry.new()


func save_player(player: Node, save_id: StringName, saved_at_unix: int, world_clock_seconds: float, raid_triggered_this_cycle: bool = false, boss_spawned: bool = false, boss_timer: float = WorldCycleState.BOSS_SPAWN_SECONDS, spawn_timer: float = WorldCycleState.INITIAL_AMBIENT_SPAWN_SECONDS, world_boss_state: WorldBossState = null) -> RefCounted:
	var snapshot_result: RefCounted = SnapshotAdapter.create_player_snapshot(player, save_id, saved_at_unix, world_clock_seconds, raid_triggered_this_cycle, boss_spawned, boss_timer, spawn_timer, world_boss_state)
	if not snapshot_result.is_accepted():
		return CoordinatorResult.new(CoordinatorResult.Status.SNAPSHOT_FAILED, 0.0, snapshot_result.status, snapshot_result.errors)
	var repository_result: RefCounted = repository.save(snapshot_result.snapshot)
	if repository_result.status != RepositoryResult.Status.SAVED:
		return CoordinatorResult.new(CoordinatorResult.Status.REPOSITORY_FAILED, 0.0, repository_result.status, repository_result.errors)
	return CoordinatorResult.new(CoordinatorResult.Status.SAVED, world_clock_seconds, repository_result.status)


func load_player(player: Node) -> RefCounted:
	var repository_result: RefCounted = repository.load_snapshot()
	if repository_result.status != RepositoryResult.Status.LOADED_PRIMARY and repository_result.status != RepositoryResult.Status.RECOVERED_BACKUP:
		return CoordinatorResult.new(CoordinatorResult.Status.REPOSITORY_FAILED, 0.0, repository_result.status, repository_result.errors)
	var migration_result: RefCounted = migration_registry.migrate(repository_result.snapshot)
	if not migration_result.is_success():
		return CoordinatorResult.new(CoordinatorResult.Status.MIGRATION_FAILED, 0.0, migration_result.status, migration_result.errors)
	var apply_result: RefCounted = ApplyAdapter.apply_player_snapshot(player, migration_result.snapshot)
	if not apply_result.is_applied():
		return CoordinatorResult.new(CoordinatorResult.Status.APPLY_FAILED, 0.0, apply_result.status, apply_result.errors)
	var success_status := CoordinatorResult.Status.LOADED_BACKUP if repository_result.status == RepositoryResult.Status.RECOVERED_BACKUP else CoordinatorResult.Status.LOADED_PRIMARY
	return CoordinatorResult.new(success_status, apply_result.world_clock_seconds, repository_result.status, PackedStringArray(), apply_result.raid_triggered_this_cycle, apply_result.boss_spawned, apply_result.boss_timer, apply_result.spawn_timer, apply_result.world_boss_state)
