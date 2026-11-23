# ConsumeZamGBA

An example consumer project demonstrating how to use the [Zamgba](https://github.com/tsetseggames/zamgba) GBA game SDK and its asset compiler toolchain (`zurag`) to build standalone Game Boy Advance (GBA) ROMs using [Zig](https://ziglang.org).

---

## 1. Prerequisites

- **Zig Compiler**: **0.17.0** or later
- **GBA Emulator**: [mGBA](https://mgba.io/) (recommended) or any GBA-compatible emulator / flashcart hardware

---

## 2. How to Build

Run `zig build` from the repository root:

```bash
# Standard debug build
zig build

# Or build with optimizations (recommended for release ROMs)
zig build -Doptimize=ReleaseFast
```

### Build Outputs
The compilation generates the following artifacts in `zig-out/bin/`:
- **`pong.gba`**: Pong game ROM.
- **`collision_demo.gba`**: 512x512 scrolling tilemap & collision demo ROM.
- **`pong`** & **`collision_demo`**: Freestanding ELF binaries containing full DWARF debug symbols (used for GDB debugging with `mgba -d`).

---

## 3. Key Demos & Architectural Features

### A. Pong (`pong.gba`)
Demonstrates basic sprite rendering, sub-pixel movement, and physics without background tilemaps:
- **Sprite Rendering**: Hardware OAM sprites for player paddle, AI paddle, and ball.
- **Fixed-Point Physics**: Sub-pixel motion calculations using `engine.physics.Fixed24_8`.
- **AABB Collision**: Axis-Aligned Bounding Box intersection testing for paddle-ball bounces and screen boundary reflections.
- **Simple AI**: Responsive tracking paddle logic.

### B. Collision & TileMap Demo (`collision_demo.gba`)
Demonstrates high-level Mode 0 background composition, camera tracking, and tilemap collision:
- **Automated VRAM Management (`BgVramManager`)**:
  - Uses `zamgba` v0.3.2+ `BgVramManager` to automatically lease Charblocks (CBB) and Screenblocks (SBB) without manual memory address math.
- **Multi-Layer Mode 0 Backgrounds**:
  - 4 layers mapped across BG0..BG3 with hardware priorities (Backdrop on BG3, Dirt on BG2, BigRock on BG1, Grass on BG0).
  - 512x512 text tilemaps (64x64 tiles) imported directly from LDtk levels.
- **Tile-Based Collision & Sliding**:
  - `CollisionMap` grid checking solid obstacle tiles (Dirt & BigRock).
  - Wall-sliding collision resolution via `player.sprite.moveAndCollide(map)`.
- **Smooth 2D Camera (`Camera2D`)**:
  - Follows the animated player with smooth dampening (`smooth_speed = 0.125`).
  - Viewport limits clamped to the 512x512 world bounds.
  - Synchronizes background scroll registers across all active tilemap layers.
- **Automated Asset Pipeline (`zurag`)**:
  - Automatically compiles Aseprite `.png` + `.json` spritesheets into Zig code modules during build time.
  - Automatically compiles LDtk (`.ldtk`) level maps and tilesets into optimized Zig data structures.

---

## 4. How to Run and Verify Results

### Running with mGBA

```bash
# Run Collision Demo
mgba zig-out/bin/collision_demo.gba

# Run Pong Demo
mgba zig-out/bin/pong.gba
```

### Verification Checklist

#### 1. Verifying `collision_demo.gba`:
- **Player Movement**: Press **D-Pad (Left / Right / Up / Down)** to steer the character riding a broom. Pressing Left/Right should flip the sprite horizontally (`h_flip`).
- **Animation**: The broom riding sprite should play a continuous multi-frame flying animation.
- **Camera Scroll**: Moving towards screen edges should smoothly scroll the 512x512 world.
- **Tilemap Collision**: Attempt to fly into Dirt or BigRock formations; the player sprite should be blocked and slide along the walls without penetrating solid tiles.
- **Layering Order**: Grass should appear in front of BigRock and Dirt, and all foreground elements should appear in front of the Backdrop layer.

#### 2. Verifying `pong.gba`:
- **Controls**: Press **D-Pad Up / Down** to control the left paddle.
- **Ball Physics**: Ball moves diagonally and reflects off top/bottom screen boundaries.
- **Paddle Collision**: Ball reflects when hitting player paddle or AI paddle.
- **Scoring & Reset**: Missing the ball resets the ball position and serves toward the scoring side.
