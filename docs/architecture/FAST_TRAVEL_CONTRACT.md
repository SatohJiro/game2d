# Fast travel contract — U2.6c

## Identity

- Destination ID thuộc domain `fast_travel`, ánh xạ deterministic 1–1 tới
  canonical chunk key: `fast_travel.<chunk_key>` (ví dụ
  `fast_travel.chunk.p1.p0`). Xem `FastTravelDestinationCatalog`.
- Không dùng localized text, asset path hoặc scene path làm identity.
  Chunk key không canonical (ví dụ `chunk.p01.p0`) bị từ chối.
- Điểm đáp là tâm hình học của chunk đích
  (`world_origin + chunk_size / 2`), deterministic và finite. An toàn
  vật lý của tile cụ thể thuộc về package chunk content, không thuộc domain.

## Policy (pure, không side effect)

`FastTravelPolicy.resolve()` nhận typed input và fail closed theo thứ tự:

1. `INVALID` — request null hoặc revision quan sát âm; discovery null.
2. `UNKNOWN_DESTINATION` — destination ID sai domain/grammar.
3. `STALE_DISCOVERY` — `observed_discovery_revision != discovery.revision`.
4. `UNDISCOVERED` — chunk đích chưa được discover.
5. `SAME_DESTINATION` — chunk đích trùng chunk hiện tại.
6. `ENCOUNTER_GUARD` — encounter đang active (xem guard).
7. `COOLDOWN_ACTIVE` — `now_msec < cooldown_until_msec`.
8. `INSUFFICIENT_COST` — không đủ cost.
9. `OK` — mang theo chunk key, landing position, cost và discovery revision.

Policy không mutate discovery, inventory, SceneTree hay player.

## Cost và cooldown

- Cost: `1 × item.pal_sphere.basic` (stable ID đã có trong registry).
- Cooldown: `30.000 msec` giữa hai lần travel thành công, do Main sở hữu
  (`fast_travel_cooldown_until_msec`, clock `Time.get_ticks_msec()`).
- Chưa autosave; cooldown là transient, không persist qua Save/load.

## Encounter guard

Travel bị chặn khi:

- `NightRaidState` đang `ACTIVE`, hoặc
- `WorldBossState` đang `ACTIVE`, hoặc
- bất kỳ creature nào trong `$Creatures` còn sống và đang target player.

Guard được tính tại thời điểm intent; scan chỉ chạy khi player ra lệnh
travel, không chạy mỗi frame.

## Atomic commit (Main boundary)

`Main.try_fast_travel(destination_id)`:

1. Policy resolve pure trước.
2. Trừ cost qua `InventoryTransaction` trên `player.inventory`.
3. Teleport player tới landing, reset velocity, chạy pipeline admission
   chuẩn (`update_chunk_admission`) để scene/navigation/spawn/discovery
   chuyển ownership đúng như một lần crossing xa.
4. Nếu admission thất bại: refund cost, khôi phục vị trí player, re-sync
   admission về chunk cũ, trả `COMMIT_FAILED`. Không partial teleport,
   không mất cost.

## Ngoài phạm vi

- UI/minimap art, fog renderer, destination picker (U2.6d).
- Autosave trước/sau travel.
- Named destination (ví dụ "trại chính"); destination = discovered chunk.
- An toàn tile đáp chi tiết (thuộc chunk content package).
