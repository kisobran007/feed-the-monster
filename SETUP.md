# Monster Tap Game Setup

## 1. Requirements

- Flutter SDK (stable)
- Chrome (for web testing)

Check installation:

```bash
flutter doctor
```

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Asset Setup

Keep assets under `assets/` with this structure:

```text
assets/
  images/
    backgrounds/
    items/
    characters/
      world1/monster_main/
      world1/monster_main/accessories/
      world2/monster_main/
      world2/monster_main/accessories/
  sounds/
```

Required monster sprite names per world:

- `idle.png`
- `happy.png`
- `sad.png`

Current accessory example:

- `assets/images/characters/world1/monster_main/accessories/hat.png`

## 4. pubspec.yaml Assets

Current project uses explicit folders:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/backgrounds/
    - assets/images/items/
    - assets/images/characters/world1/monster_main/
    - assets/images/characters/world1/monster_main/accessories/
    - assets/images/characters/world2/monster_main/
    - assets/images/characters/world2/monster_main/accessories/
    - assets/sounds/
```

If you add new deep folders, include them here.

## 5. Run the Game

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

## 6. Common Web Asset Fix

If web shows missing asset errors (404):

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Then hard refresh browser (`Ctrl+Shift+R`).

## 7. Gameplay Controls

- Start screen: `Start The Game`, `My Monster`
- In-game: `Menu` button (top-right)
  - `Resume`
  - `Start New Game`
  - `My Monster`

## 8. Customization Flow

- Coins are earned from gameplay score.
- In `My Monster`, player can:
  - preview accessory
  - unlock/apply if enough coins
  - remove equipped accessory
- Equipped accessory is shown on monster in gameplay.
