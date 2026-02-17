# Feed The Monster - Project Context

This file is a quick handover/context reference for future sessions.
Keep it updated when gameplay rules, assets, or structure change.

## Current Game State

- Framework: Flutter + Flame.
- Progression model: world-based (`world1 -> world2`), no level system.
- Game loop:
  - Tap good items for score.
  - Tap bad items or miss good items to lose lives and points.
  - Game over when lives reach 0.
- In-game menu (top-right `Menu`):
  - `Resume`
  - `Start New Game`
  - `My Monster`

## Economy and Cosmetics

- Currency: `coins` (displayed in HUD as `Gold`).
- Coins are earned from run score.
- Current accessory implemented:
  - `Classic Hat` for `world1/monster_main`.
- Accessory flow:
  - Preview available in `My Monster` even when locked.
  - Unlock requires enough coins.
  - Apply/remove supported.
  - When equipped, hat appears in gameplay on monster states (`idle`, `happy`, `sad`).

## Important Files

- App/menu shell: `lib/app/game_shell.dart`
- Main game logic: `lib/game/monster_tap_game.dart`
- Monster + accessory overlay logic: `lib/game/components/monster.dart`
- HUD: `lib/game/components/score_display.dart`
- Game over overlay: `lib/game/components/game_over_display.dart`
- World transition overlay: `lib/game/overlays/world_transition_overlay.dart`
- World enum: `lib/game/models/game_world.dart`

## Asset Conventions

- Character sprites are world + monster scoped.
- Naming convention for monster states per world:
  - `idle.png`
  - `happy.png`
  - `sad.png`
- Current paths:
  - `assets/images/characters/world1/monster_main/`
  - `assets/images/characters/world2/monster_main/`
- Accessories:
  - `assets/images/characters/world1/monster_main/accessories/hat.png`

## pubspec Asset Registration

Use explicit folders (important for web packaging):

- `assets/images/backgrounds/`
- `assets/images/items/`
- `assets/images/characters/world1/monster_main/`
- `assets/images/characters/world1/monster_main/accessories/`
- `assets/images/characters/world2/monster_main/`
- `assets/images/characters/world2/monster_main/accessories/`
- `assets/sounds/`

## Known Decisions

- `Best score` is not shown in UI (HUD/Game Over), but score persistence code may still exist internally.
- `Menu` replaced the old standalone pause button.
- `Start New Game` uses dedicated flow (`startNewGameFromMenu`) to avoid pause/resume freeze.

## Common Web Troubleshooting

If assets fail on web (404 / unable to load asset):

1. `flutter clean`
2. `flutter pub get`
3. `flutter run -d chrome`
4. Hard refresh browser (`Ctrl+Shift+R`)

## Suggested Next Work

- Expand accessory catalog (multiple hats/badges).
- Add per-monster/per-world skin catalog data model.
- Add coins earned summary on game-over UI.
- Add tests for unlock/equip persistence and menu flows.
