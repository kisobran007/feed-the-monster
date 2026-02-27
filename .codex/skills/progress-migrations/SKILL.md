---
name: progress-migrations
description: Evolve local/cloud progress schema safely for this game. Use when adding, renaming, or removing progress fields in SharedPreferences or Firestore, including migration logic, backward compatibility, and merge behavior.
---

# Progress Migrations

Change persistence without breaking existing players.

## Follow this workflow

1. Define the schema delta.
- List old keys, new keys, and expected fallback values.
- Decide if migration is one-time, always-on normalization, or both.

2. Implement migration in repository load path.
- Use `lib/game/services/progress_repository.dart` as the single migration authority.
- Migrate legacy IDs/keys during load before game state is consumed.
- Keep save output normalized to the newest schema.

3. Preserve backward compatibility.
- Continue reading legacy keys until adoption is stable.
- Never assume cloud data completeness; guard null/invalid values.

4. Validate merge semantics.
- Confirm local/cloud merge is monotonic for progression (no accidental progress loss).
- Prefer max/union style merges for unlocks and stars unless explicitly changing policy.

5. Document migration intent in code.
- Add short comments only where migration rules are non-obvious.

## Regression checklist

- Existing local users load successfully.
- Existing cloud users load successfully.
- First save after migration writes normalized schema.
- Selected monster/level/accessory remains valid after migration.
- Unlock rules and coin totals remain consistent.
