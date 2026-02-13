# Monster Tap Game 🟢🍎

A simple, fun, and addictive **Flutter 2D game** targeted at children aged **4–8 years**. The main goal is to tap on “good” items to earn points while avoiding “bad” items. The game is designed to be visually appealing with cute, cartoonish graphics, easy controls, and a clear, kid-friendly interface.

---

## 🎯 Game Concept

- **Target audience:** Children 4–8 years old
- **Game type:** Tap-based casual game
- **Gameplay:**
  - Tap on good items (fruits, cookies) to gain points
  - Avoid bad items (shoes, rocks) that deduct points or end the game
  - Score increases with each correct tap

- **Goal:** Collect as many points as possible before making mistakes or reaching game limits.

---

## 🖼 Visual Style

- **Art style:** Cartoonish, semi-realistic, cute and kid-friendly
- **Format:** PNG, transparent background, 512×512 pixels
- **Colors:** Bright, contrasting colors for good items; dull/gray/brown for bad items
- **Character:** A “cute monster” as a central figure (optional for game theme or mascots)

---

## 🍏 Good Items

These items give points when tapped:

| Item        | Emoji | Description |
|------------|-------|-------------|
| Apple      | 🍎    | Red, cute, cartoon-style apple |
| Banana     | 🍌    | Bright yellow, curved, kid-friendly style |
| Cookie     | 🍪    | Golden brown, chocolate chips, scattered crumbs |
| Strawberry | 🍓    | Red with seeds, small, round, cute |

*Each item has its own PNG asset for easy integration in Flutter.*

---

## 👎 Bad Items

These items should be avoided:

| Item | Description |
|------|-------------|
| Shoe | Old, worn sneaker with mud, sad expression |
| Rock | Gray, uneven, cartoon-style rock |

*Bad items decrease score or trigger a game-over event.*

---

## 🛠 Development Notes

- **Platform:** Flutter (iOS, Android, Web)
- **Asset management:** Each item is a separate PNG file
- **Controls:** Tap on items to interact
- **Recommended workflow for graphics:**
  1. Draw in **Corel Painter** (raster digital painting)
  2. Clean background / edit in **Photopea** or **GIMP**
  3. UI elements (buttons/icons) can be made in **CorelDRAW Standard**
- **Naming convention:** snake_case, e.g., `apple.png`, `cookie.png`, `bad_shoe.png`

---

## 🔮 Next Steps / Features

- Implement **score system** for good/bad items
- Add **animations** for taps (pop, bounce)
- Optional **monster character** for player feedback
- **Game over screen** and restart button
- Optional **background themes** for variety
- Potential **level progression** for extra challenge

---

## 📂 Example Asset Folder Structure

```
assets/
├─ items/
│  ├─ apple.png
│  ├─ banana.png
│  ├─ cookie.png
│  ├─ strawberry.png
│  ├─ bad_shoe.png
│  └─ bad_rock.png
└─ characters/
   └─ monster.png
```

---