# Hashlife synchronizeState Bug: Stale Caches & Canonical Table Corruption

## Symptom

Placing gliders/cells works correctly on first launch, but after running the simulation and then pausing/resetting, newly placed cells are ignored by the Hashlife algorithm.

## Root Cause

`synchronizeState()` was mutating `HLNode` instances in-place. These nodes are shared through the canonical node table (`canonicalNodes`) and carry cached `result` fields from previous `nextGeneration()` computations. Two bugs resulted:

### Bug 1: Stale `result` cache (primary cause)

`nextGeneration(for:)` caches its output on each node via `node.result`. When `synchronizeState()` mutated a node's children to reflect new cell state, the `result` field was never cleared. On the next simulation step, `nextGeneration` would return the stale cached result immediately, completely ignoring the new cells.

### Bug 2: Canonical table corruption

Nodes in `canonicalNodes` are keyed by `NodeKey`, which includes `ObjectIdentifier` references to their children. When `synchronizeState()` replaced a node's children (e.g., `node.nw = Self.alive`), the node's actual children no longer matched the key under which it was stored. Future `join()` calls could retrieve nodes whose children didn't match the requested combination.

## Fix

Replaced the mutation-based `synchronizeState()` with a full tree rebuild:

```swift
public func synchronizeState() {
    // Clear canonical table to discard stale result caches and corrupted entries
    Self.canonicalNodes.removeAll(keepingCapacity: true)
    Self.canonicalNodes[Self.dead.id] = Self.dead
    Self.canonicalNodes[Self.alive.id] = Self.alive

    // Rebuild tree from the grid
    root = Self.construct(grid: grid, xStart: 0, xEnd: xCount, yStart: 0, yEnd: yCount)
    rootCenterZeroNode = Self.getZeroNode(at: root.level - 1)
}
```

Additionally, `HLNode` properties (`population`, `nw`, `ne`, `sw`, `se`) were changed from `var` to `let` to enforce immutability at the compiler level and prevent this class of bug from recurring.

## Additional fixes in same changeset

- `construct()` base case coordinate convention changed from `grid[x][y]` to `grid[y][x]` to match `updateCells()`, making the read/write round-trip consistent.
- `CellGrid` methods (`reset`, `placeSpaceship`, `randomState`, `makeAllLive`) moved `synchronizeState()` calls inside `updateQueue.sync` blocks for thread safety.
- `HLNode.synchronizePopulation()` removed (no longer needed with immutable nodes).

## Cost

`synchronizeState()` is only called on user interaction (touch, reset, pattern placement), not every frame. Rebuilding is O(N) — same as the old mutation walk. Losing the memoization cache is acceptable because the tree state has fundamentally changed and old cached results would be wrong anyway.
