# Receipt — AT-H visual & audio refresh (user feedback 2026-10-08)

Feedback: map/characters not pretty enough; music needs to be more peaceful/chill.

## Sprite source evaluation

- Downloaded Kenney "Tiny Town", "Tiny Dungeon", "Tiny Farm" (CC0-1.0, kenney.nl) and evaluated.
- Rejected for direct use: western-medieval style clashes with the anime/Japanese town direction; character sprites are single-frame (no 4-direction walk cycles) and cannot satisfy the hero/pet animation contracts.
- LimeZu packs rejected: free tier is private-projects-only; paid tier forbids redistribution (repo is public).
- Decision: upgraded original art (style-coherent, provenance clean). Kenney remains a documented CC0 fallback.

## Town art

Tool: `tools/generate_town_art.py` (rewritten — anime detail pass: tiled roofs, machiya walls, lattice windows, noren, shimenawa, dithered gradients). Same 19 sprites, same footprints, palette-constrained to the validator sets. License: CC0-1.0 (Paloria project originals). Status: VERIFIED

## Hero / pet / NPC art

Tool: `tools/generate_hero_art.py` (rewritten — anime-chibi: navy hair w/ highlight, blush, scarf, satchel, sword poses; fluffy palfox; elder/merchant/kid NPCs). Contracts unchanged (hero 4x7, palfox 4x4, NPC 4x4). License: CC0-1.0. Status: VERIFIED

## Music

Tool: `tools/synthesize_town_audio.py` (rewritten — chill lo-fi: Rhodes-style EP, sub bass, pentatonic koto pluck, pads, echo, vinyl crackle; 58-72 BPM; no square waves/hats). Same 6 cues + 7 ambience beds. License: CC0-1.0. Status: VERIFIED

| file | size | sha256 |
|---|---|---|
| assets/town/bridge.png | 1167 | 7c89ac5f1644f07abd902cb01d484e42695ec0b9e35cbfe56cea8bcd95a0a2fa |
| assets/town/bulletin.png | 730 | 79c859159bd457ef6e4381ce4e090761575e25845d88a7862f6b75b4cb043c36 |
| assets/town/clock_tower.png | 1574 | dae7b00a5cbb49e833b2a770876fe7df99ebe0a48080db8773f1d5ec7d08ac2a |
| assets/town/dock.png | 609 | a7f4c51f8c2e3390018e62aa088377f43afdec3be2f570c295c97fee6c66404a |
| assets/town/house_a.png | 1825 | 6328cec4356e5cb89f7c17298070b4020546f601cf87e60b724467f88864ae80 |
| assets/town/house_b.png | 2059 | 4924ddf34179782f47a10dc8e79eb33e2a2d00dff364853f7db490cfa92ce892 |
| assets/town/lake.png | 23317 | e466117c2a6b3935823c479407fd58cf3ef0d2e025daabf01985c87c0692209b |
| assets/town/platform.png | 982 | 7651293a7a2de78c70087190ea710a3c537c3489f7ab2e100699c385d299b9b5 |
| assets/town/plaza_tile.png | 935 | 7752e14b66fd9596cf8f52861d93e92694cb683490f47cc7307271544126f790 |
| assets/town/power_pole.png | 459 | 89ebce668970db4dc2a20a2506cde5861115e1c1f2ad47f54b6f63f1cbe3e987 |
| assets/town/sakura_tree.png | 1561 | ce36974da0b785178645e93b20b01aef7d33d8f7d7f925ed7163d6b3fd53ae24 |
| assets/town/shrine_hall.png | 2936 | 854e16045194507d9af791a0ba5588dff8bb34a159620bc7b23f3fb35d185534 |
| assets/town/stall.png | 1052 | 9ae5fad7e945c38a4f9b4e62ccc9c79536c15ebe1d873abfa994526ec0d74675 |
| assets/town/station_hall.png | 2509 | 74b58c5c8c3d4efabb841d8f5ce9877db548fcc7fb3f68960ec484960de64298 |
| assets/town/stone_lantern.png | 463 | bd1b7e0a30abc1d04abdd4d3060e7e37fbbb73b163be12a26954e01a7a3a5d8b |
| assets/town/stone_path.png | 1170 | b313da88bc34dc5cfc4265c4a37b45fd8a8ea25e5ea9f2c4aadd2d8b0f463cf1 |
| assets/town/torii.png | 1025 | d0e569ebbe35714e484ad11ca8b6981989af63152e9d0f8594c0063ec77b78f8 |
| assets/town/town_gate.png | 630 | 9f5ce9448e43e59cc155b7585438fd5d50361dd2e74aee633cb74f40f2400f91 |
| assets/town/vending.png | 868 | d81dfeaa42986aa536e9e0a11962d35fff8e8ae25ed6bc8135bb8bad58d011e6 |
| assets/hero/hero_sheet.png | 2498 | ddcd6fbda90b29f55147a5183c40291a1e21404ca79e7b06dba941b6797a8132 |
| assets/hero/npc_elder.png | 998 | 9d36cb98034c9d7685623508893b77b9e7d29045f9c47f449c00007e3961f756 |
| assets/hero/npc_kid.png | 782 | d3bec6f6244e9cf7ecb69c7a45ce9ffa77d72ad06cf45b2bd18fc23ee8aa2548 |
| assets/hero/npc_merchant.png | 950 | 7f69c08978a199b2881cfba609e88504a297b9c6e5c70fc2125c0c8e917ea34e |
| assets/hero/palfox_sheet.png | 1362 | 8eeb80a0d17b77fc720a315453b2cf0bed64cf126e5c0691593f5e0cff72d98c |
| assets/audio/music/music_outskirts_danger.ogg | 165176 | 85107efdc5d4b056691ff5913da7221420e89da33e06710d75bd6133b9861d8b |
| assets/audio/music/music_shrine_story.ogg | 159629 | bcdae99dbdad3e51b0690ac98b949dc3dcbb0ce460c04ef32a05eca4b0d9f70a |
| assets/audio/music/music_town_day.ogg | 125462 | 75ac6a4db9e0a48520171ab7850680ced454db5390f47df4d748637cac779bcb |
| assets/audio/music/music_town_dusk.ogg | 140912 | 24a617378c1d8fa06f33d51534be9f05ec48eb644e065bc13b7080b07e3d0f70 |
| assets/audio/music/music_town_night.ogg | 159273 | 5d8c77ad7492c6e3e0ab782c94a332acd7c7d40360366fb976dd38410f5f6381 |
| assets/audio/music/music_town_rain.ogg | 168057 | ae065c167014f7933094cc9296f3f527fb93cb07e01778856ee9d0577b803dfc |
| assets/audio/ambience/amb_birds.ogg | 69714 | 14b06d6ae2806376f8a629c603957ab1f9e26586c0f66e745fac72ee75204e07 |
| assets/audio/ambience/amb_cicadas.ogg | 89597 | eedced37512199dd071ac737d9da322716fb398f619b10e98cf6a83646cdc7ee |
| assets/audio/ambience/amb_crickets.ogg | 13499 | 60ed679d83ad4495f72bf2604f72edbbfc15fe630da06a10a4a403e5d0ae22c4 |
| assets/audio/ambience/amb_rain.ogg | 60539 | 8abb97aeb0c6bffc1beb8eb10565f0077f372104e22c0003e94277762e0253a9 |
| assets/audio/ambience/amb_train.ogg | 67647 | 817ef32b54f9b4142d3a3c6b54bc7f9860166c8a08fe4b13aef6ad853ddf3cb3 |
| assets/audio/ambience/amb_water.ogg | 58176 | 5450bccbf175aee501d0803d2c6046fd5a72311d8e5910de01df0b548dcb4b30 |
| assets/audio/ambience/amb_wind.ogg | 57296 | 698cd93eddb2d1dec58245bc31684a1be2a9c38569971b60ad7b7c715012da75 |
