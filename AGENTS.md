# ConsumeZamGBA Agent Guidelines

This document provides essential context for AI agents working in the `consumezamgba` repository.

## Project Overview

`consumezamgba` is a template/example consumer project demonstrating how to use the [zamgba](https://github.com/fuzhouch/zamgba) library SDK as a dependency to build custom Game Boy Advance (GBA) ROMs in **Zig** (targeting Zig version **0.17.0** or later).

---

## Code Organization & Structure

- **`build.zig`**: Build script defining the GBA ROM target using `zamgba`'s build helper `gba.arm.addROM(...)` and configuring module imports (`zamgba` imported as `"gba"`).
- **`build.zig.zon`**: Package manifest specifying package metadata, minimum Zig version (`0.17.0`), and remote git package dependency (`zamgba`).
- **`src/main.zig`**: ROM entry point demonstrating GBA initialization, header export, and hardware manipulation (Mode 3 bitmap rendering).

---

## Essential Commands

### Build
```bash
zig build
```
- Produces the debug ELF binary with symbol tables at `zig-out/bin/first`.
- Produces the raw binary GBA ROM at `zig-out/bin/first.gba` via `objcopy` (`-O binary`).

### Run & Emulation
To run the generated ROM in the [mGBA](https://mgba.io/) emulator:
```bash
mgba ./zig-out/bin/first.gba
```

### Debugging
To launch mGBA with GDB remote debugging enabled (connects via GDB on port 2345):
```bash
mgba -d ./zig-out/bin/first.gba
```

---

## Architecture & GBA Conventions

### 1. GBA ROM Header Requirement
The GBA BIOS performs a checksum on the cartridge ROM header at boot (`0x08000000`).
In client code, the header must be exported at the `.gba.header` linker section:
```zig
const gba = @import("gba");

export var gameHeader linksection(".gba.header") = gba.hal.setupROMHeader(
    "FIRST",   // Game Title (up to 12 uppercase ASCII characters)
    "AFSE",    // Game Code (4 uppercase ASCII characters)
    "00",      // Maker Code (2 uppercase ASCII characters)
    0,         // Software Version
);
```

### 2. Exported `main` Entry Point
The low-level assembly bootloader (`_start` and `_boot` in `zamgba-hal`) branches to the exported `main` symbol:
- `main` **must** be marked with `export fn main() noreturn`.
- Because GBA bare-metal hardware has no operating system to return to, `main` must end with an infinite loop:
```zig
export fn main() noreturn {
    // Game initialization & main loop
    while (true) {
        // Frame loop
    }
}
```

### 3. Module Hierarchy in `zamgba`
When importing `"gba"`, the SDK exposes two primary submodules:
- `gba.hal`: Hardware Abstraction Layer (direct register mapping, `display`, `joypad`, `oam`, `context`, `waitForVBlank`, memory sections).
- `gba.engine`: High-level engine components (2D drawing algorithms `gfx2d`, `sprite`, `color`, `physics` AABB collision detection, fixed-point math `Fixed24_8`).

### 4. Direct Memory / Register Access
- **I/O Registers (IORAM)**: `0x04000000` (e.g., `REG_DISPCNT` at `0x04000000`, `REG_VCOUNT` at `0x04000006`, `REG_KEYINPUT` at `0x04000130`).
- **PALRAM (Palette)**: `0x05000000`.
- **VRAM (Video RAM)**: `0x06000000` (96 KiB).
- **OAM (Object Attribute Memory)**: `0x07000000` (1 KiB).
- **PAKROM (Cartridge ROM)**: `0x08000000`.

---

## Gotchas & Non-Obvious Patterns

- **Target Architecture**: GBA builds target `thumb-freestanding` with CPU `arm7tdmi` and `+thumb_mode`. Standard POSIX/OS APIs and host standard library I/O (like `std.debug.print` or file operations) are unavailable in ROM code.
- **Linker Script (`gba.ld`)**: Zamgba relies on a custom linker script to map `.gba.header`, `.gba.start`, `.gba.boot`, `.data`, and `.bss` into IWRAM/EWRAM/PAKROM.
- **Running ELF vs GBA**: The ELF output (`zig-out/bin/first`) contains debug symbols for GDB, but emulators and flash cartridges expect the raw binary (`zig-out/bin/first.gba`).
- **Zig 0.17.0+ Syntax**: Zig 0.17.0 uses lowercase calling conventions (e.g. `callconv(.naked)` instead of older `.Naked`) and `std.Build.LazyPath` / `b.path(...)` in `build.zig`.
