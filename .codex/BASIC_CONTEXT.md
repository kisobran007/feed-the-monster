# Feed The Monster - Base Context

This document is a quick onboarding reference for development and maintenance.
It is intended to be the primary context file under `.codex`.

## Project Overview

- Type: educational kids game (Flutter + Flame)
- Core loop: drag good items to the monster, drag bad items to the trash bin
- Current state: level-based gameplay, coin economy, monster/accessory unlocks, cloud save sync (Firebase)

## Tech Stack

- Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- Flame (`flame`, `flame_audio`)
- Local persistence: `shared_preferences`
- Cloud/auth: `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`

## Current Gameplay

- 10 levels (`GameLevel.level1` to `GameLevel.level10`)
- Each level defines:
  - time limit
  - objectives (`feedHealthy`, `throwJunk`, `maxMistakes`)
  - spawn/fall multipliers and higher-level modifier chances (`freeze`, `fake`, `bomb`)
- Mistakes progress the `maxMistakes` objective toward failure; run also fails on timeout
- Level completion grants 1-3 stars and coins based on best-star progression

## Progression and Economy

- Coins are earned from improved best-star results per level
- Level unlock rule: previous level must have at least 1 star
- Supported systems:
  - monster unlock/select
  - accessory unlock/equip per target (`level + monster + slot`)
- Progress is stored locally and merged with cloud progress when the user is signed in

## UI and Flows

- Start overlay: start, shop, levels, settings, exit
- In-game `Menu`: resume, start new game, shop, levels, settings, exit
- Pause, game-over, and level-complete flows are separated
- Account/settings panel supports Google sign-in + cloud sync/disconnect

## Key Files

- `lib/main.dart` - app entry point + `part` declarations
- `lib/app/game_shell.dart` - app shell, overlay flows, auth/settings UI
- `lib/game/monster_tap_game.dart` - core game logic, spawn, objective handling, completion/failure
- `lib/game/models/game_world.dart` - level definitions and objective models
- `lib/game/services/progress_repository.dart` - local/cloud progress load, save, merge
- `lib/game/services/objective_engine.dart` - objective rules and run tracking
- `lib/app/dialogs/` - levels/shop/level-complete dialogs

## Asset Conventions

- Backgrounds: `assets/images/backgrounds/`
- Items: `assets/images/items/`
- Monsters: `assets/images/characters/<monster_id>/`
- Accessories (currently focused on `monster_main`):
  - `assets/images/characters/monster_main/accessories/`
- Trash bin: `assets/images/trash_bin/`
- Audio: `assets/sounds/`

## Run Commands

```bash
flutter pub get
flutter run
```

If web assets appear stale:

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Then hard-refresh the browser (`Ctrl+Shift+R`).

## Notes

- This file can replace the old root-level `PROJECT_CONTEXT.md`.
- Keep this document updated whenever gameplay rules, progression, or asset structure changes.
