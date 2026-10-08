# U1.13b — Player craft transaction contract

## Phạm vi và invariant

Package tách 17 recipe runtime khỏi `scripts/player.gd`, giữ nguyên input/output, unlock level, thứ tự card, text/icon, HUD/audio/quest callback và build-mode behavior. Không thêm queue, craft time, station logistics, UI mới hoặc Save field.

- `PlayerCraftDefinition` là typed Resource; `recipe_id`, input `item.*` và result `item.*`/`equipment.*`/`building.*` là identity.
- Localized name, icon path và success text chỉ là presentation, không được dùng để resolve outcome.
- Resolver chỉ đọc stable inventory snapshot và trả `PlayerCraftResult`; invalid/locked/insufficient không mutate.
- Transaction thử remove/add trên shadow legacy store rồi mới replace backing dictionary. Source đổi sau resolve làm commit thất bại nguyên khối.
- Player chỉ commit accepted equipment/building result và render feedback; item mutation không còn được viết trực tiếp trong craft handler.

## Runtime IDs

Catalog admit 17 ID:

- Item: `recipe.item.organic_fertilizer`, `recipe.item.stamina_elixir`, `recipe.item.pal_sphere_basic`, `recipe.item.pal_sphere_mega`, `recipe.item.pal_sphere_giga`.
- Equipment: `recipe.equipment.iron_sword`, `recipe.equipment.pal_blade`, `recipe.equipment.pal_warrior_armor`.
- Building: `recipe.building.cooking_pot`, `compost_bin`, `ranch`, `furnace`, `chest`, `turret`, `altar`, `farm_plot`, `wood_fence`.

Legacy short IDs chỉ được nhận tại `PlayerCraftCatalog.get_definition()` như compatibility input. HUD projection mới phát stable `recipe.*`.

## API và ownership

- `PlayerCraftCatalog`: typed definition authority và HUD projection.
- `PlayerCraftResolver.resolve(recipe_id, player_level, stable_inventory)`: pure decision.
- `PlayerCraftTransaction.commit(legacy_inventory, result)`: atomic shadow commit.
- `Player.craft_recipe()`: presentation/equipment/build adapter.

Regression nằm trong `tools/validate_item_migration.gd`: catalog validity/uniqueness, stable HUD identity, insufficient/locked behavior, item conservation, stale-source atomicity, stable building result và live Player equipment adapter.

Save/data breaking change: none. Inventory vẫn có một legacy backing dictionary; Save adapter tiếp tục project `item.*`. Asset/provenance: none.
