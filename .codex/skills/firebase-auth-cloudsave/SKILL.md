---
name: firebase-auth-cloudsave
description: Implement or debug Google sign-in and Firebase cloud save synchronization for this game. Use when changing authentication flow, account panel behavior, cloud sync triggers, or Firestore persistence reliability.
---

# Firebase Auth Cloud Save

Handle account and sync flows with graceful fallbacks.

## Follow this workflow

1. Validate runtime preconditions.
- Check Firebase initialization status before auth/sync operations.
- Handle web-specific configuration gaps clearly.

2. Keep auth UX resilient.
- Distinguish cancel, recoverable failure, and hard failure paths.
- Surface clear user feedback for sign-in, sync, and disconnect actions.

3. Keep progress sync deterministic.
- Use repository load/save as the only persistence gateway.
- After sign-in, refresh game state from merged progress.

4. Preserve offline/local behavior.
- If cloud is unavailable, local progress must continue to work.
- Never block core gameplay on auth availability.

5. Validate account panel flows.
- Not connected -> connect
- Connected -> sync now
- Connected -> disconnect
- Re-open panel and ensure state is accurate

## Guardrails

- Do not assume authenticated user is always present.
- Wrap Firestore interactions in failure-safe handling.
- Keep cloud save idempotent and merge-friendly.
