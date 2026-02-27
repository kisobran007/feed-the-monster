---
name: asset-pipeline
description: Add, replace, or validate game assets and registrations for Flutter/Flame builds. Use when working with item sprites, monster states, accessories, backgrounds, trash bin art, or audio files to prevent missing/stale asset issues.
---

# Asset Pipeline

Manage assets with strict consistency.

## Follow this workflow

1. Place assets in canonical folders.
- Backgrounds: `assets/images/backgrounds/`
- Items: `assets/images/items/`
- Monsters: `assets/images/characters/<monster_id>/`
- Accessories: `assets/images/characters/monster_main/accessories/`
- Trash bin: `assets/images/trash_bin/`
- Sounds: `assets/sounds/`

2. Apply naming conventions.
- Keep lowercase snake_case names.
- Preserve expected state filenames for monsters (`idle.png`, `happy.png`, `sad.png`).

3. Register and reference safely.
- Ensure relevant folders are included in `pubspec.yaml`.
- Ensure runtime code references exact filenames.

4. Run stale-asset prevention flow for web when needed.
- `flutter clean`
- `flutter pub get`
- `flutter run -d chrome`
- Hard refresh (`Ctrl+Shift+R`)

5. Validate in gameplay.
- Confirm asset loads in the actual scene/dialog where used.
- Confirm no fallback or missing-texture behavior.

## Guardrails

- Do not leave temporary copy files as active runtime references.
- Prefer folder-level registration only for directories actually used.
- Remove or ignore placeholder files from runtime logic.
