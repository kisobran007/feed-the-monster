---
name: ui-overlay-flow
description: Modify start/pause/menu/dialog UI flows in the game shell without breaking state transitions. Use when changing overlays, menu actions, settings/account panels, or game pause/resume interactions.
---

# UI Overlay Flow

Update UI flows while preserving state integrity.

## Follow this workflow

1. Map current state flags first.
- Review `hasStarted`, `isPaused`, `isMenuOpen`, and game flags before changes.
- Use `lib/app/game_shell.dart` as the source of truth for overlay orchestration.

2. Implement transitions explicitly.
- Define what each action does to UI state and game engine state.
- Keep pause/resume calls paired with overlay visibility changes.

3. Protect gameplay from UI regressions.
- Prevent menu operations while game is not started or already over.
- Ensure restart/new game paths clear pause and menu state correctly.

4. Keep dialogs composable.
- Shop/levels/settings dialogs should temporarily hide pause menu and restore it only when appropriate.
- Handle `mounted` checks after async dialogs.

5. Verify interaction matrix.
- Start -> play -> pause -> resume
- Pause -> shop/levels/settings -> return
- Level complete -> continue
- Fail -> restart path

## Guardrails

- Avoid duplicated state updates in multiple handlers.
- Prefer small helper methods for repeated transition patterns.
- Keep visual changes separate from game-logic mutations.
