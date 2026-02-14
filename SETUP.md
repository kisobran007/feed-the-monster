# Monster Tap Game - Flutter Setup Guide

## 🚀 Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Add PNG Assets
Place the following PNG files (512×512px, transparent background) in the specified folders:

#### `assets/characters/`
- `monster.png` - Cute monster character (centered, idle state)

#### `assets/items/`
**Good Items (bright colors):**
- `apple.png` - Red cartoon apple 🍎
- `banana.png` - Yellow curved banana 🍌
- `cookie.png` - Golden cookie with chocolate chips 🍪
- `strawberry.png` - Red strawberry with seeds 🍓

**Bad Items (dull colors):**
- `bad_shoe.png` - Old worn sneaker 👟
- `bad_rock.png` - Gray cartoon rock 🪨

### 3. Run the Game
```bash
flutter run
```

---

## 🎮 How to Play

- **Tap good items** (fruits, cookies) to earn +10 points
- **Avoid bad items** (shoe, rock) which deduct -5 points
- **Game Over** when score drops below 0
- **Tap screen** after game over to restart

---

## 📁 Project Structure

```
feed-the-monster-dev/
├── lib/
│   └── main.dart              # Complete game code
├── assets/
│   ├── characters/
│   │   └── monster.png        # [ADD THIS]
│   └── items/
│       ├── apple.png          # [ADD THIS]
│       ├── banana.png         # [ADD THIS]
│       ├── cookie.png         # [ADD THIS]
│       ├── strawberry.png     # [ADD THIS]
│       ├── bad_shoe.png       # [ADD THIS]
│       └── bad_rock.png       # [ADD THIS]
├── pubspec.yaml
└── README.md
```

---

## 🧩 Code Architecture

### Main Components:

1. **MonsterTapGame** - Main game controller
   - Manages score, game state, item spawning
   - Handles tap detection and game over logic

2. **Monster** - Character component
   - Displays at bottom center
   - Shows reactions (happy/oops/idle)

3. **FallingItem** - Falling object component
   - Spawns randomly at top
   - Falls downward at constant speed
   - Detects taps and triggers score changes

4. **ScoreDisplay** - UI text component
   - Shows current score at top-left

5. **GameOverDisplay** - Game over screen
   - Shows final score
   - Provides restart functionality

---

## 🎨 Asset Creation Tips

Use **Corel Painter** or similar tools to create:
- Cartoonish, kid-friendly style
- Bright contrasting colors for good items
- Dull gray/brown for bad items
- PNG format with transparent background
- 512×512 pixels recommended

---

## 🔧 Customization

### Adjust Difficulty:
- Change `spawnInterval` in MonsterTapGame (line 28)
- Modify `fallSpeed` in FallingItem (line 145)

### Adjust Scoring:
- Good item points: line 73 (`score += 10`)
- Bad item penalty: line 76 (`score -= 5`)

### Add More Items:
- Add PNG to `assets/items/`
- Update spawn logic in `spawnRandomItem()` (line 58)

---

## ✅ Ready to Play!

Once you've added all PNG assets, run `flutter run` and enjoy the game!
