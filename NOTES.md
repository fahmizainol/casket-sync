# Casket of Reveries world snapshot: notes for AI agents

A partial snapshot of the Minecraft world "rotters (fixed)", synced automatically every 5 minutes while NIG has the game open, plus once when it closes.
Use it to answer questions about inventories, equipment, quests, storage networks, and team progress.
`git pull` first to get the latest snapshot. The commit time is the snapshot time.

## Pack
- **The Casket of Reveries 2.2.9.8**: Minecraft 1.20.1, Forge 47.4.4, about 200 mods. Runs in Prism Launcher.
- Difficulty: pack difficulty level 3 / **Hard** (`/tcrcore difficulty <level>`). Mobs deal about 2x damage and have about 1.5x HP.
- Cheats are enabled for all players on the LAN host, so `/give` works.

## Players (offline-mode UUIDs)
| Player | UUID |
|---|---|
| NIG (world host) | `4160a5c8-62ae-32ae-bcef-9d00a1d04297` |
| TOP_G | `37cffe65-595b-3b39-b612-abca535a04fd` |

Both are in the FTB team "NIG's Party" (NIG is the owner). Quest progress and the goddess-statue blessings sync across the team.

## Layout
- `world/`: raw copies of the save files (gzip NBT). Includes `playerdata/<uuid>.dat`, `data/`, `advancements/`, `stats/`, `ftbquests/`, `ftbteams/`, `level.dat`, and others.
- `readable/`: the same `.dat` files converted to JSON. **Read these first.**
  - `readable/playerdata/<uuid>.json`: `Inventory` (Slot 0-8 hotbar, 9-35 main, 100-103 armor, -106 offhand), `EnderItems`, `Pos`, `Dimension`, `XpLevel`, `Health`. Curios accessories are under `ForgeCaps."curios:inventory"`. Epic Fight skills and other mod data are also under `ForgeCaps`.
  - `readable/data/BDNet_0.json`: Beyond Dimensions network storage for **TOP_G**. `BDNet_1.json` is **NIG**'s.
  - `readable/data/tcr_level_save_data.json`: tcrcore pack state (difficulty and others).
- `world/ftbquests/`, `world/ftbteams/`: SNBT text files that you can read directly.
- `tools/nbt2json.py`: converter (`python tools/nbt2json.py file.dat`).

**Not included:** the map files (`region/`, `entities/`, `poi/`, `dimensions/`), about 860 MB. Questions about block positions, chests, or where mobs are can't be answered from this repo. Ask NIG for a one-off copy.

## Pack quirks (verified by reading the jars and configs)
- **tcrcore overrides many recipes.** It disables some recipes with empty JSON files, so a recipe shown on the wiki or in a mod's own docs may not exist in this pack. Check JEI in game, or look for "Couldn't parse data file" in `logs/latest.log`.
  - Known disabled examples: some EpicFight Nightfall weapon recipes and the Dodos Mobs Amalgam Claws crafting recipe.
  - Netherite has an alternative recipe: a smithing table with a lava bucket, `quark:diamond_heart`, and a gold block.
- **The Nether** needs a portal lit with tcrcore **Core Flint**. A normal flint and steel doesn't work.
- **Enchanting:** a vanilla-style table. Quark's Enchantments Begone removes Unbreaking and Mending. TaxFreeLevels removes the anvil "Too Expensive" limit. Enchanting Infuser blocks are also available.
- **Ability points** (epicfight-skilltree) come from ability stones given as quest rewards. tcrcore removes the XP-to-points conversion, and stones don't drop from mobs.
- **Eyes of God:** each one comes from a boss. Praying at the goddess statue (in `tcrcore:sanctum`) gives the blessing once per eye type per player, and the blessing syncs to the team.
- **Battle Towers:** the Ocean Golem fight can be restarted with `ba_bt:ocean_monolith` plus 3 `ba_bt:ocean_monolith_key`.
- **Dragons** (Book of Dragons): bound through the tcrcore dragon flute. TOP_G's flute slot 30 holds a stale duplicate copy of a Night Fury and should be ignored.
- Configs for mobs (Cataclysm, Battle Towers, and others) are in the instance's `config/` folder, which is not in this repo.
