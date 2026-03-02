# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

The project uses Xcode with no external dependencies. Build with:

```bash
# macOS (default scheme)
xcodebuild -scheme "Conway's Game of Life Reloaded macOS" -configuration Release

# iOS (simulator)
xcodebuild -scheme "Conway's Game of Life Reloaded iOS" -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16'

# tvOS
xcodebuild -scheme "Conway's Game of Life Reloaded tvOS" -configuration Release -destination 'platform=tvOS Simulator,name=Apple TV'
```

There are also `[Release]` prefixed schemes that default to Release configuration. No test targets exist. No linter is configured. Release builds use `-Ofast` for maximum performance.

## Architecture

**Language**: Swift, **Framework**: SpriteKit (rendering), **Platforms**: iOS 15+, macOS 12+, tvOS, watchOS

### Shared Core (`Conway's Game of Life Reloaded Shared/`)

The game engine is entirely in the Shared directory. Platform targets only contain UI controllers and storyboards/XIBs.

**Cell** (`Cell.swift`) — A `final class` representing one cell. Each cell holds:
- `currentState`/`nextState` booleans for double-buffered state updates
- A `ContiguousArray<Cell>` of pre-computed neighbor references (set once at init, enabling O(1) neighbor lookup)
- An `SKSpriteNode` for rendering (uses `isHidden` toggle, not alpha — this is a deliberate performance optimization)
- `prepareUpdate()` counts live neighbors and computes `nextState`; `update()` applies the change only if `needsUpdate()` returns true

**CellGrid** (`CellGrid.swift`) — Owns a 2D `ContiguousArray<ContiguousArray<Cell>>` grid. The simulation loop in `updateCells()` runs two phases:
1. `prepareUpdate()` on all cells (parallel via `DispatchQueue.concurrentPerform` over x-axis)
2. `update()` only on cells where state changed (lazy-filtered, also parallel over x-axis)

Uses two separate dispatch queues: `updateQueue` for the simulation loop, `userInputQueue` with barrier flags for thread-safe touch/mouse input during simulation.

**GameScene** (`GameScene.swift`) — SpriteKit scene that drives the game loop via `update(_ currentTime:)`. Default grid is 800x800 cells at 6pt cell size. Update interval is user-configurable. Uses `#if os()` conditional compilation for platform-specific input handling (touch on iOS/tvOS, mouse on macOS). Camera system supports zoom.

**Pattern Factories** — `SpaceshipFactory` creates Glider and Square patterns. `ShapeFactory` builds basic rectangles. `GunFactory` creates a Gosper Glider Gun. All factories work by computing `[CGPoint]` arrays that map to grid coordinates.

### Platform Targets

Each platform directory contains `AppDelegate`, `GameViewController`, and UI resources (storyboards/XIBs). The macOS target additionally has `GameWindowController` with toolbar controls (zoom slider, speed slider, spaceship selector popup). The iOS target has a speed popup (`SpeedViewController`) and pinch-to-zoom gesture support.

### Key Protocols
- `GameSceneDelegate` — callbacks from scene to controller (e.g., `setGeneration(_:)`)
- `GameWindowDelegate` — window-level event handling
- `ResettableScene` — scene reset protocol

## Performance Considerations

This codebase is heavily performance-optimized. When making changes:

- `Cell` is a `final class` with `@inlinable @inline(__always)` on hot-path methods — maintain these annotations
- `ContiguousArray` is used instead of `Array` throughout for better memory layout
- The `isHidden` approach for cell visibility is ~2x faster than changing alpha — do not switch back to alpha-based rendering
- `.replace` blend mode on sprite nodes avoids costly blending
- `lazy.filter` in update loops prevents intermediate array allocation
- The commented-out code blocks in `CellGrid.updateCells()` are preserved performance experiments (double concurrentPerform, buffer pointer approaches, quadrant splitting) — these document optimization history
- `timeit()` calls throughout are active profiling instrumentation

## Current Branch Context

The `tino/hashlife` branch indicates exploration of the HashLife algorithm for more efficient simulation of large/sparse grids.
