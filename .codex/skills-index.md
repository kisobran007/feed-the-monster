# Skills Index

This index is the quick routing guide for project skills in `.codex/skills`.

## Required Starting Point

Always read and use `.codex/BASIC_CONTEXT.md` as the baseline project context before applying any skill.

Reason:
- It contains the canonical overview of architecture, gameplay rules, progression, key files, and asset conventions.
- Skills below are task-specific layers on top of that baseline.

## Skills Overview

### 1) `flutter-flame-feature`
- Path: `.codex/skills/flutter-flame-feature/SKILL.md`
- Purpose: implement or modify core gameplay features.
- Use for:
  - new game mechanics
  - spawn behavior changes
  - objective/HUD logic updates
  - item modifier behavior (`freeze`, `fake`, `bomb`)
- Main focus: safe changes in `monster_tap_game.dart` + related models/components.

### 2) `progress-migrations`
- Path: `.codex/skills/progress-migrations/SKILL.md`
- Purpose: evolve save schema safely.
- Use for:
  - SharedPreferences key changes
  - Firestore progress structure changes
  - migration/normalization logic
  - local-cloud merge policy updates
- Main focus: backward compatibility and zero progress loss.

### 3) `content-level-designer`
- Path: `.codex/skills/content-level-designer/SKILL.md`
- Purpose: design and balance levels/content.
- Use for:
  - tuning time limits and objectives
  - changing difficulty ramp across levels
  - updating good/bad item pools per level
  - adjusting modifier probabilities
- Main focus: playable, progressive difficulty without sharp regressions.

### 4) `asset-pipeline`
- Path: `.codex/skills/asset-pipeline/SKILL.md`
- Purpose: manage assets and registrations.
- Use for:
  - adding/replacing sprites, backgrounds, sounds
  - validating folder and filename conventions
  - fixing missing/stale asset issues (especially web)
- Main focus: consistent asset paths and correct `pubspec.yaml` registration.

### 5) `ui-overlay-flow`
- Path: `.codex/skills/ui-overlay-flow/SKILL.md`
- Purpose: change UI/menu/dialog flows safely.
- Use for:
  - start/pause/menu behavior updates
  - dialog navigation and return flows
  - settings/account panel interactions
- Main focus: state integrity (`hasStarted`, `isPaused`, `isMenuOpen`) and no flow breakage.

### 6) `firebase-auth-cloudsave`
- Path: `.codex/skills/firebase-auth-cloudsave/SKILL.md`
- Purpose: auth + cloud save reliability.
- Use for:
  - Google sign-in flow changes
  - cloud sync/disconnect behavior
  - Firestore progress sync/debugging
- Main focus: resilient UX and deterministic sync with local fallback.

## Practical Routing

- Gameplay behavior changed? Use `flutter-flame-feature`.
- Save/progress keys or merge behavior changed? Use `progress-migrations`.
- Level tuning/content balance task? Use `content-level-designer`.
- Any new/replaced media files? Use `asset-pipeline`.
- Menu/overlay/dialog interaction changed? Use `ui-overlay-flow`.
- Sign-in/sync/account issue? Use `firebase-auth-cloudsave`.

## Operating Rule for Future Sessions

1. Start with `.codex/BASIC_CONTEXT.md`.
2. Select one primary skill from this index.
3. If needed, combine with one secondary skill only.
4. Keep changes aligned with existing project architecture and conventions.
