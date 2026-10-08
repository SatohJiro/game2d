class_name FastTravelPolicy
extends RefCounted

## Pure domain policy for fast travel.
##
## Every rejection happens before any mutation: unknown/stale/undiscovered/
## same-destination intents, active encounter guards, cooldown and missing
## cost all fail closed. The policy never touches the SceneTree, inventory or
## player; the caller (Main) owns the atomic commit and rollback.

const COST_ITEM_ID := &"item.pal_sphere.basic"
const COST_AMOUNT := 1
const COOLDOWN_MSEC := 30000


static func resolve(
	request: FastTravelRequest,
	discovery: ChunkDiscoveryState,
	current_chunk_key: StringName,
	available_counts: Dictionary,
	encounter_blocked: bool,
	cooldown_until_msec: int,
	now_msec: int
) -> FastTravelResult:
	var destination_id := &""
	if request != null:
		destination_id = request.destination_id
	if request == null or request.observed_discovery_revision < 0:
		return FastTravelResult.new(FastTravelResult.Status.INVALID, destination_id)
	if discovery == null:
		return FastTravelResult.new(FastTravelResult.Status.INVALID, destination_id)
	var chunk_key := FastTravelDestinationCatalog.chunk_key_for_destination(destination_id)
	if chunk_key == &"":
		return FastTravelResult.new(
			FastTravelResult.Status.UNKNOWN_DESTINATION, destination_id,
			&"", Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	if request.observed_discovery_revision != discovery.revision:
		return FastTravelResult.new(
			FastTravelResult.Status.STALE_DISCOVERY, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	if not discovery.get_discovered_keys().has(chunk_key):
		return FastTravelResult.new(
			FastTravelResult.Status.UNDISCOVERED, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	if chunk_key == current_chunk_key:
		return FastTravelResult.new(
			FastTravelResult.Status.SAME_DESTINATION, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	if encounter_blocked:
		return FastTravelResult.new(
			FastTravelResult.Status.ENCOUNTER_GUARD, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	if now_msec < cooldown_until_msec:
		return FastTravelResult.new(
			FastTravelResult.Status.COOLDOWN_ACTIVE, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	if int(available_counts.get(COST_ITEM_ID, 0)) < COST_AMOUNT:
		return FastTravelResult.new(
			FastTravelResult.Status.INSUFFICIENT_COST, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	var landing: Array[Vector2] = []
	if not FastTravelDestinationCatalog.try_landing_position(chunk_key, landing):
		return FastTravelResult.new(
			FastTravelResult.Status.INVALID, destination_id,
			chunk_key, Vector2.ZERO, COST_ITEM_ID, COST_AMOUNT, discovery.revision
		)
	return FastTravelResult.new(
		FastTravelResult.Status.OK, destination_id,
		chunk_key, landing[0], COST_ITEM_ID, COST_AMOUNT, discovery.revision
	)
