---
name: flutter-flame-feature
description: Add or modify gameplay features in this Flutter + Flame game, including spawn behavior, item modifiers, objectives, HUD updates, and level rules. Use when implementing a new mechanic or adjusting an existing in-game feature that touches game logic and UI.
---

# Flutter Flame Feature

Implement game features with small, testable changes.

## Follow this workflow

1. Identify the feature entry points.
- Check `lib/game/monster_tap_game.dart` for runtime logic and event handling.
- Check `lib/game/models/game_world.dart` for level parameters and progression knobs.
- Check `lib/game/services/objective_engine.dart` for objective bookkeeping.
- Check `lib/game/components/` for HUD/visual feedback updates.

2. Implement behavior in the game loop first.
- Keep spawn/update logic deterministic and easy to reason about.
- Avoid mixing UI dialog logic into core game logic.
- Prefer extending existing helpers over adding parallel code paths.

3. Wire player feedback.
- Update HUD text/progress if gameplay rules changed.
- Add visual/audio feedback only when it communicates gameplay state.

4. Update data and asset dependencies.
- Add any new asset path in `pubspec.yaml` if needed.
- Ensure naming follows existing item/monster conventions.

5. Verify no flow regressions.
- Start game, pause/resume, restart, and level complete/fail flows must still work.
- Confirm coins/stars progression still updates correctly after the feature.

## Quality checklist

- Keep changes minimal and localized.
- Reuse existing constants and models where possible.
- Avoid hardcoding values in multiple places.
- Include at least one focused test when practical.
