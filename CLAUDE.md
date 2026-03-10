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

**CellGrid** (`CellGrid.swift`) — Owns a 2D `ContiguousArray<ContiguousArray<Cell>>` grid. Delegates simulation to a `LifeAlgorithm` instance (currently `Hashlife`, previously `NaiveConcurrent`). The `updateCells()` method calls `algorithm.update(generation:)`. After user-initiated state changes (reset, pattern placement, random state), `algorithm.synchronizeState()` is called to keep the algorithm's internal representation in sync with the grid.

Uses two separate dispatch queues: `updateQueue` for the simulation loop, `userInputQueue` with barrier flags for thread-safe touch/mouse input during simulation.

**GameScene** (`GameScene.swift`) — SpriteKit scene that drives the game loop via `update(_ currentTime:)`. Default grid is 800x800 cells at 6pt cell size. Update interval is user-configurable. Uses `#if os()` conditional compilation for platform-specific input handling (touch on iOS/tvOS, mouse on macOS). Camera system supports zoom.

**Pattern Factories** — `SpaceshipFactory` creates Glider and Square patterns. `ShapeFactory` builds basic rectangles. `GunFactory` creates a Gosper Glider Gun. All factories work by computing `[CGPoint]` arrays that map to grid coordinates.

### Algorithm Layer (`Algorithms/`, `Protocols/`, `DataStructures/`)

**LifeAlgorithm** (`Protocols/LifeAlgorithm.swift`) — Protocol defining the simulation interface:
- `update(generation:) -> UInt64` — advance one generation and return the new generation count
- `synchronizeState()` — re-read the Cell grid to rebuild internal state (called after user edits like reset, pattern placement, random fill)

**NaiveConcurrent** (`Algorithms/NaiveConcurrent.swift`) — The original brute-force algorithm. Two-phase concurrent update: `prepareUpdate()` on all cells, then `update()` on changed cells only. Both phases parallelized via `DispatchQueue.concurrentPerform` over the x-axis. `synchronizeState()` is a no-op since this algorithm reads directly from the Cell grid. Contains extensive commented-out performance experiments (buffer pointers, quadrant splitting, double concurrentPerform).

**Hashlife** (`Algorithms/Hashlife.swift`) — HashLife algorithm implementation using a quadtree with memoization. Key design:
- Builds a quadtree (`HLNode`) from the Cell grid via recursive `construct()`, splitting the grid into NW/NE/SW/SE quadrants down to 2x2 base cases
- **Canonical node table**: `canonicalNodes: [Int: HLNode]` maps hash values to shared node instances, enabling structural sharing and memoization
- `join(nw:ne:sw:se:)` — creates or retrieves a canonical node from four children, keyed by `NodeKey` (uses `ObjectIdentifier` of child nodes)
- `nextGeneration(for:)` — recursive HashLife step: at level 2, applies life rules directly via `applyLifeRules4x4()`; at higher levels, computes 9 overlapping sub-results (sliding window pattern) and combines inner quadrants
- `applyLifeRules(for:neighbors:)` — applies B3/S23 rules to a single leaf node given its 8 neighbors
- `center(node:)` — expands the universe by one level, padding with dead nodes (used before `nextGeneration` to prevent boundary loss)
- `synchronizeState()` — walks the quadtree and re-reads `Cell.alive` from the grid to update leaf nodes, then propagates population counts up
- `updateCells(node:xStart:yStart:size:)` — walks the result quadtree and writes `nextState`/`update()` back to each Cell for rendering
- `expand(node:)` — flattens a quadtree back to a `[Bool]` array (used for debugging)
- **Status**: Work in progress on `tino/hashlife` branch — functional but still being debugged and optimized

**HLNode** (`DataStructures/HLNode.swift`) — Quadtree node for HashLife:
- `level: UInt64` — 0 for leaf (single cell), 1 for 2x2, 2 for 4x4, etc.
- `population: UInt64` — total live cells in subtree
- `nw`, `ne`, `sw`, `se` — four child nodes (nil for level-0 leaves)
- `id: Int` — hash-based identity for canonical table lookup
- Level-0 nodes use population (0 or 1) as id; higher levels use `NodeKey.hashValue`
- `synchronizePopulation()` — recomputes population from children (used during state sync)
- `NodeKey` struct uses `ObjectIdentifier` of child nodes for identity-based hashing

### Platform Targets

Each platform directory contains `AppDelegate`, `GameViewController`, and UI resources (storyboards/XIBs). The macOS target additionally has `GameWindowController` with toolbar controls (zoom slider, speed slider, spaceship selector popup). The iOS target has a speed popup (`SpeedViewController`) and pinch-to-zoom gesture support.

### Key Protocols
- `LifeAlgorithm` — simulation algorithm interface (`update`, `synchronizeState`)
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
- The commented-out code blocks in `NaiveConcurrent.update()` are preserved performance experiments (double concurrentPerform, buffer pointer approaches, quadrant splitting) — these document optimization history
- `timeit()` calls throughout are active profiling instrumentation

## Current Branch Context

The `tino/hashlife` branch contains an in-progress HashLife algorithm implementation. The algorithm is functional — it builds a quadtree from the cell grid, computes next generations via recursive memoized decomposition, and writes results back to the Cell grid for rendering. CellGrid currently uses `Hashlife` as its algorithm (switchable back to `NaiveConcurrent` by changing one line in `CellGrid.init`). Known areas still being worked on:
- Grid requires power-of-2 dimensions for the quadtree decomposition
- Canonical node table uses `hashValue` as dictionary key (potential hash collisions)
- Result caching/memoization of `nextGeneration` results not yet implemented (this is the key HashLife speedup)
- `updateCells` tree walk is sequential (TODO comment about making concurrent)
- `synchronizeState` replaces leaf nodes rather than mutating population in-place (earlier approach was commented out)
