---
name: content-level-designer
description: Design or rebalance game levels and item pools for Feed The Monster. Use when adding levels, tuning objectives/time/difficulty, or adjusting good-vs-bad item sets and modifier probabilities.
---

# Content Level Designer

Tune level content with a consistent difficulty ramp.

## Follow this workflow

1. Edit level definitions.
- Update `lib/game/models/game_world.dart` for objectives, time limits, and multipliers.
- Keep level IDs and numbering stable unless a migration is intentional.

2. Align runtime content pools.
- Update per-level good/bad item pools in `lib/game/monster_tap_game.dart`.
- Ensure every referenced item has a valid asset file.

3. Balance difficulty progressively.
- Increase challenge using one axis at a time: objective volume, time pressure, spawn rate, fall speed, or modifier chance.
- Avoid sudden spikes between consecutive levels unless intentionally designed.

4. Validate completion feasibility.
- Ensure targets are achievable within time limits under realistic play.
- Keep early levels forgiving and readable for younger players.

5. Verify unlock economy impact.
- Check stars/coins effects after rebalance.
- Confirm one-star threshold still provides healthy progression.

## Balancing guardrails

- Early levels prioritize clarity and success confidence.
- Mid levels introduce complexity gradually (`freeze`, `fake`, then `bomb`).
- Late levels test consistency, not randomness-only luck.
