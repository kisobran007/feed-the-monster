# Monster Tap Game

Kid-friendly Flutter + Flame game where the player feeds a monster by tapping good items and avoiding bad ones.

## Current Features

- World-based progression (`World 1 -> World 2`) by score threshold.
- Falling item gameplay with score/lives system.
- Particle effects and simple reaction animations.
- In-game menu with:
  - `Resume`
  - `Start New Game`
  - `My Monster`
- Monster customization entry (`My Monster`) from both start screen and in-game menu.
- Coins currency for cosmetics.
- Accessory system (currently `Classic Hat` for World 1 monster):
  - Preview in customization screen (even when locked)
  - Unlock/apply flow with coins
  - Equipped accessory appears in gameplay across monster states (`idle`, `happy`, `sad`).
- Persistent progress with `SharedPreferences`:
  - coins
  - unlocked/equipped accessory state
  - best score (stored internally)

## Project Structure

```text
lib/
  main.dart
  app/
    game_shell.dart
  game/
    monster_tap_game.dart
    models/
      game_world.dart
    components/
      monster.dart
      falling_item.dart
      score_display.dart
      game_over_display.dart
    overlays/
      world_transition_overlay.dart
    effects/
      tap_burst.dart
```

## Asset Structure

```text
assets/
  images/
    backgrounds/
      bg_meadow.png
      bg_world2.png
    items/
      apple.png
      banana.png
      cookie.png
      strawberry.png
      bad_shoe.png
      bad_rock.png
      bad_soap.png
      bad_brick.png
      cupcake.png
      lollipop.png
      chili.png
      onion.png
    characters/
      world1/
        monster_main/
          idle.png
          happy.png
          sad.png
          accessories/
            hat.png
      world2/
        monster_main/
          idle.png
          happy.png
          sad.png
          accessories/
            PLACE_ACCESSORIES_HERE.txt
  sounds/
    ...
```

## Run

```bash
flutter pub get
flutter run
```

For web, if assets seem stale after changes:

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Then hard refresh browser (`Ctrl+Shift+R`).

## Notes

- HUD currently shows `Score`, `Gold`, `World`, lives, and goal text.
- `Best score` is not shown in UI anymore.
- Coins are earned from run score and spent in `My Monster`.
