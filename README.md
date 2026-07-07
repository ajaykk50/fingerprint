# EchoPrint: Escape the Fingerprint

> "The maze remembers you."

EchoPrint is a 2D puzzle adventure game built using Flutter and the Flame Engine. The player is a digital particle trapped inside a live, procedurally generated biometric fingerprint scanner. Armed with a draining flashlight, the player must navigate the biometric ridges, solve gate puzzles, bypass security patrols, and escape through the core.

---

## 🏗️ Architecture & Folder Structure

The project implements a strict separation of concerns, following Clean Architecture and Repository Patterns:

```
lib/
 ├── core/
 │    ├── config/
 │    │    ├── dependency_injection.dart  # GetIt Service Locator
 │    │    ├── router.dart                # GoRouter Screen mapping
 │    │    └── theme.dart                 # Sci-fi Neon palettes
 │    ├── repository/
 │    │    └── game_repository.dart       # Mediation of Hive saves and progress
 │    └── services/
 │         ├── audio_service.dart         # FlameAudio sound manager
 │         └── storage_service.dart       # Hive local database
 ├── game/
 │    ├── engine/
 │    │    ├── echo_print_game.dart       # Main Flame game loop
 │    │    └── game_cubit.dart            # Flutter Bloc game session controller
 │    └── world/
 │         ├── components/
 │         │    ├── collectibles.dart     # DNA, Battery cells, Keys
 │         │    ├── enemies.dart          # AI Drones, Patrols, Lasers
 │         │    └── puzzles.dart          # Doors, Plates, Teleporters
 │         ├── levels/
 │         │    └── level_config.dart     # 285 dynamic level constructor
 │         ├── maze/
 │         │    ├── fingerprint_generator.dart # Mathematical warping generator
 │         │    └── maze_component.dart   # Ridge drawer
 │         └── player/
 │              ├── lighting_mask_component.dart # Fog of War & Flashlight canvas blending
 │              └── player_component.dart # Glowing orb and swiping path interpolation
 └── ui/
      └── presentation/
           └── screens/
                ├── game_play_screen.dart # HUD and game widget viewport
                ├── level_select_screen.dart # Play selection grid
                ├── main_menu_screen.dart # Landing portal
                └── settings_screen.dart  # Audio & data config
```

---

## 📐 Mathematical Coordinate Warping

To guarantee that every maze is 100% solvable while rendering natural, curved fingerprint ridges, we use a **Coordinate Warping Transform**. 

We generate a topological rectangular grid maze (via Randomized Prim's Algorithm) and warp every cell corner coordinate $(x,y)$ into screen space coordinates $(X_{screen}, Y_{screen})$:

### 1. Whorl (Concentric Circles)
Maps the rectangular coordinate grid to Polar coordinates:
$$R = \frac{y}{rows} \cdot R_{max}$$
$$\theta = \frac{x}{cols} \cdot 2\pi$$
$$X_{screen} = C_x + R \cos(\theta), \quad Y_{screen} = C_y + R \sin(\theta)$$

### 2. Spiral (Archimedean Flow)
Warp offset dynamically expands the radius based on theta turns:
$$\theta = \frac{x}{cols} \cdot 2\pi \cdot 4$$
$$R = \left(\frac{y}{rows} + \frac{x}{cols} \cdot 0.1\right) \cdot R_{max}$$
$$X_{screen} = C_x + R \cos(\theta), \quad Y_{screen} = C_y + R \sin(\theta)$$

### 3. Arch (Upward Parabolic Wave)
Horizontally stretches the grid X and projects Y upward using a Gaussian peak:
$$X_{screen} = C_x + \left(\frac{x}{cols} - 0.5\right) \cdot W$$
$$Y_{screen} = C_y + \left(\frac{y}{rows} - 0.5\right) \cdot H - 120 \cdot e^{-12\left(\frac{x}{cols} - 0.5\right)^2}$$

### 4. Loop (U-Turn Ridge fold)
Traces lines folding back down:
$$X_{screen} = C_x + \left(\frac{x}{cols} - 0.5\right) \cdot W$$
$$Y_{screen} = C_y + \left(\frac{y}{rows} - 0.5\right) \cdot H - 60 \sin\left(\frac{x}{cols} \cdot \pi\right)$$

---

## 🔦 Dynamic Lighting Mask & Fog of War

Lighting calculations operate at 60 FPS using hardware-accelerated canvas destination-out compositing (`BlendMode.dstOut`). The rendering flow:

1. Game objects (walls, collectibles, player, enemies) render normally.
2. A single `LightingMaskComponent` draws a solid black rectangle covering the canvas.
3. For each cell marked as `explored`, a soft white circle is drawn with 18% opacity using `BlendMode.dstOut`. This subtracts opacity from the black layer, resulting in a dark gray path (Fog of War).
4. Centered on the player, a radial gradient circle is drawn using `BlendMode.dstOut` from 100% white to 0% white, creating a smooth fading flashlight beam.
5. `canvas.restore()` layers the composited mask over the viewport.

---

## 🎮 Gameplay Loop

1. **Explore**: Swipe left, right, up, or down. The orb smoothly interpolates grid paths.
2. **Tension**: Flashlight battery drains constantly based on movement and level settings. Collect Battery Cells to recharge.
3. **Puzzles**: Stand on Pressure Plates to deactivate security Laser Doors, use Teleporter nodes to navigate isolated cells.
4. **Enemies**: Evade Patrol Bots, Scanner Eyes rotating sweep lasers, Light Eaters, and Ghost trackers.
5. **Escape**: Navigate to the blinking Fingerprint Core at the center of the warped space.

---

## 🛠️ Build and Running

### Setup Assets
To build the directories and mock assets, run the asset generator script:
```bash
dart tool/generate_assets.dart
```

### Get Dependencies
```bash
flutter pub get
```

### Run Project
```bash
flutter run
```

### Run Tests
```bash
flutter test
```
