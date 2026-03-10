# HashLife Performance Improvements

Top 5 performance and efficiency improvements for the HashLife algorithm implementation, ranked by impact.

---

## 1. Memoize `nextGeneration` Results on Each Node

**Impact: 10x-1000x+ depending on pattern**

This is **the** defining optimization of HashLife and it's not yet implemented. Currently `nextGeneration(for:)` recomputes the full recursive decomposition every call, even for identical subtrees. With an 800x800 grid, the same work is being done millions of times redundantly.

### Problem

`Hashlife.swift:204-232` — Every call to `nextGeneration` performs the full 9-window recursive decomposition, even when the exact same node (same children, same configuration) was already computed in a previous generation or elsewhere in the tree.

### Solution

Add a `result` cache field to `HLNode`:

```swift
// In HLNode.swift:
var result: HLNode?  // cached nextGeneration output
```

Then short-circuit at the top of `nextGeneration`:

```swift
public func nextGeneration(for node: HLNode) -> HLNode {
    // Return cached result if available:
    if let cached = node.result {
        return cached
    }

    // Empty node:
    if node.population == 0 {
        return node.nw!
    }

    let result: HLNode

    if node.level == 2 {
        result = applyLifeRules4x4(node: node)
    } else {
        // ... existing sliding window logic ...
        result = Self.join(nw: ngNW, ne: ngNE, sw: ngSW, se: ngSE)
    }

    node.result = result
    return result
}
```

### Why This Matters

Game of Life patterns naturally produce massive spatial repetition (empty regions, repeating still lifes, oscillators). With memoization, all identical subtrees resolve to the same canonical node, and their results are computed exactly once. This turns repeated subtree computation from exponential to O(1) lookup. Without this, HashLife is actually **slower** than the naive approach due to all the quadtree overhead.

---

## 2. Fix the Canonical Node Table to Use `NodeKey` Directly

**Impact: correctness fix + better cache hit rates**

### Problem

`Hashlife.swift:195-201` — The canonical table uses `key.hashValue` as the dictionary key:

```swift
private static var canonicalNodes: [Int: HLNode] = [:]

// In join():
if let existing = canonicalNodes[key.hashValue] {  // BUG: hashValue is not unique
    return existing
}
let node = HLNode(level: nw.level + 1, id: key.hashValue, nw: nw, ne: ne, sw: sw, se: se)
canonicalNodes[key.hashValue] = node
```

`hashValue` is **not unique**. Different `NodeKey` values can produce the same hash, causing silent collisions where one node overwrites another in the dictionary. This is both:

- A **correctness bug**: wrong simulation results when two different node configurations hash to the same integer
- A **performance bug**: destroys the structural sharing that the canonical table is meant to provide, because legitimate cache entries get evicted by unrelated nodes

### Solution

Change the table type from `[Int: HLNode]` to `[NodeKey: HLNode]` and key on the `NodeKey` struct itself:

```swift
private static var canonicalNodes: [NodeKey: HLNode] = [:]

static func join(nw: HLNode, ne: HLNode, sw: HLNode, se: HLNode) -> HLNode {
    let key = NodeKey(nw: ObjectIdentifier(nw),
                      ne: ObjectIdentifier(ne),
                      sw: ObjectIdentifier(sw),
                      se: ObjectIdentifier(se))

    if let existing = canonicalNodes[key] {
        return existing
    }

    let node = HLNode(level: nw.level + 1, nw: nw, ne: ne, sw: sw, se: se)
    canonicalNodes[key] = node
    return node
}
```

`NodeKey` is already `Hashable` — Swift's `Dictionary` handles collision resolution correctly when the full struct is used as the key. The `HLNode.id` field can be removed entirely since it was only used for this (broken) lookup.

---

## 3. Eliminate Array Allocations in `applyLifeRules`

**Impact: ~2-4x faster for the level-2 base case**

### Problem

`Hashlife.swift:142-146` — Every call allocates a heap-allocated `[HLNode]` array of 8 neighbors, then `map`s and `reduce`s over it:

```swift
func applyLifeRules(for node: HLNode, neighbors: [HLNode]) -> HLNode {
    let liveNeighbors = neighbors.map((\.population)).reduce(0, +)
    let alive = liveNeighbors == 3 || (liveNeighbors == 2 && node.population == 1)
    return alive ? Self.alive : Self.dead
}
```

This is called 4 times per level-2 node (once per inner cell of the 4x4 grid). For an 800x800 grid with ~40,000 level-2 nodes, that's **160,000 array allocations per generation**, each with 8 elements. The `map` also creates a second intermediate array of `UInt64` values.

### Solution

Replace with direct integer counting using individual parameters:

```swift
@inlinable @inline(__always)
func applyLifeRules(center: HLNode,
                    n0: HLNode, n1: HLNode, n2: HLNode, n3: HLNode,
                    n4: HLNode, n5: HLNode, n6: HLNode, n7: HLNode) -> HLNode {
    let count = n0.population &+ n1.population &+ n2.population &+ n3.population
              &+ n4.population &+ n5.population &+ n6.population &+ n7.population
    let alive = count == 3 || (count == 2 && center.population == 1)
    return alive ? Self.alive : Self.dead
}
```

Then update `applyLifeRules4x4` to pass arguments directly:

```swift
func applyLifeRules4x4(node: HLNode) -> HLNode {
    let nw = applyLifeRules(center: node.nw!.se!,
                            n0: node.nw!.nw!, n1: node.nw!.ne!, n2: node.nw!.sw!,
                            n3: node.ne!.nw!, n4: node.ne!.sw!,
                            n5: node.sw!.nw!, n6: node.sw!.ne!, n7: node.se!.nw!)

    let ne = applyLifeRules(center: node.ne!.sw!,
                            n0: node.ne!.nw!, n1: node.ne!.ne!, n2: node.ne!.se!,
                            n3: node.se!.nw!, n4: node.se!.ne!,
                            n5: node.sw!.ne!, n6: node.nw!.ne!, n7: node.nw!.se!)

    let sw = applyLifeRules(center: node.sw!.ne!,
                            n0: node.sw!.nw!, n1: node.sw!.sw!, n2: node.sw!.se!,
                            n3: node.se!.nw!, n4: node.se!.sw!,
                            n5: node.ne!.sw!, n6: node.nw!.se!, n7: node.nw!.sw!)

    let se = applyLifeRules(center: node.se!.nw!,
                            n0: node.se!.ne!, n1: node.se!.se!, n2: node.se!.sw!,
                            n3: node.ne!.sw!, n4: node.ne!.se!,
                            n5: node.nw!.se!, n6: node.sw!.ne!, n7: node.sw!.se!)

    return Self.join(nw: nw, ne: ne, sw: sw, se: se)
}
```

Zero heap allocations, no indirection, compiler can keep everything in registers. The `@inlinable @inline(__always)` annotations match the project's existing performance conventions.

---

## 4. Stop `updateCells` Recursion at Level 1

**Impact: ~2x faster grid writeback**

### Problem

`Hashlife.swift:270-284` — The tree walk recurses all the way to level 0 (individual cells), meaning for an 800x800 grid there are ~640K leaf-level function calls plus ~640K intermediate calls. Each level-0 call does one cell update but pays the full cost of a function call, branch, and stack frame.

### Solution

Stop at level 1 (2x2 nodes) and unroll the four cell updates directly:

```swift
private func updateCells(node: HLNode, xStart: Int, yStart: Int, size: Int) {
    if node.level == 1 {
        // Directly update 4 cells without recursing to level 0:
        grid[yStart][xStart].nextState = (node.nw! === Self.alive)
        grid[yStart][xStart].update()

        grid[yStart][xStart + 1].nextState = (node.ne! === Self.alive)
        grid[yStart][xStart + 1].update()

        grid[yStart + 1][xStart].nextState = (node.sw! === Self.alive)
        grid[yStart + 1][xStart].update()

        grid[yStart + 1][xStart + 1].nextState = (node.se! === Self.alive)
        grid[yStart + 1][xStart + 1].update()
    } else {
        let half = size / 2
        updateCells(node: node.nw!, xStart: xStart,        yStart: yStart,        size: half)
        updateCells(node: node.ne!, xStart: xStart + half,  yStart: yStart,        size: half)
        updateCells(node: node.sw!, xStart: xStart,        yStart: yStart + half, size: half)
        updateCells(node: node.se!, xStart: xStart + half,  yStart: yStart + half, size: half)
    }
}
```

This cuts the total number of recursive calls roughly in half. As a further enhancement, `concurrentPerform` can be added at a mid-level (e.g., level 4 or 5) to parallelize the four quadrant walks:

```swift
// At a sufficiently high level (e.g., level >= 5), parallelize:
if node.level >= 5 {
    let half = size / 2
    DispatchQueue.concurrentPerform(iterations: 4) { quadrant in
        switch quadrant {
        case 0: updateCells(node: node.nw!, xStart: xStart,        yStart: yStart,        size: half)
        case 1: updateCells(node: node.ne!, xStart: xStart + half,  yStart: yStart,        size: half)
        case 2: updateCells(node: node.sw!, xStart: xStart,        yStart: yStart + half, size: half)
        case 3: updateCells(node: node.se!, xStart: xStart + half,  yStart: yStart + half, size: half)
        default: break
        }
    }
}
```

---

## 5. Avoid Unconditional `center()` Every Generation

**Impact: prevents O(n) tree depth growth, keeps operations at fixed depth**

### Problem

`Hashlife.swift:313` — Every `update()` call wraps the root in `center()`, adding a new level of empty border nodes:

```swift
public func update(generation: UInt64) -> UInt64 {
    updateQueue.sync {
        let centeredRoot = Self.center(node: root)  // grows tree every frame
        root = nextGeneration(for: centeredRoot)
        updateCells(node: root, xStart: 0, yStart: 0, size: xCount)
    }
    return generation + 1
}
```

After 100 generations the tree is 100+ levels deep with vast empty regions. This makes `nextGeneration` traverse deeper, `updateCells` recurse through more empty levels, and the canonical table bloat with empty-border nodes.

### Solution

**Option A** — Only center when live cells are near the border:

```swift
func needsExpansion(_ node: HLNode) -> Bool {
    guard let nw = node.nw, let ne = node.ne,
          let sw = node.sw, let se = node.se else { return false }
    // Check if any outermost grandchildren have live cells:
    return nw.nw!.population != 0 || nw.ne!.population != 0 || nw.sw!.population != 0
        || ne.nw!.population != 0 || ne.ne!.population != 0 || ne.se!.population != 0
        || sw.nw!.population != 0 || sw.sw!.population != 0 || sw.se!.population != 0
        || se.ne!.population != 0 || se.sw!.population != 0 || se.se!.population != 0
}

public func update(generation: UInt64) -> UInt64 {
    updateQueue.sync {
        var currentRoot = root
        if needsExpansion(currentRoot) {
            currentRoot = Self.center(node: currentRoot)
        }
        root = nextGeneration(for: currentRoot)
        updateCells(node: root, xStart: 0, yStart: 0, size: xCount)
    }
    return generation + 1
}
```

**Option B** — Since the grid is fixed-size (800x800) with no infinite expansion needed, `center()` may not be needed at all. The boundary cells can simply be treated as always-dead. This keeps the tree at a constant depth of log2(800) ~ 10 levels, which is optimal for all tree operations.

---

## Summary

| # | Improvement | Expected Impact | Type |
|---|-------------|----------------|------|
| 1 | Memoize `nextGeneration` results | 10x-1000x+ | Algorithmic |
| 2 | Fix canonical table (`NodeKey` vs `hashValue`) | Correctness + cache hits | Correctness/Algorithmic |
| 3 | Eliminate array allocations in `applyLifeRules` | ~2-4x base case speedup | Constant-factor |
| 4 | Stop `updateCells` recursion at level 1 | ~2x grid writeback | Constant-factor |
| 5 | Conditional `center()` / fixed-depth tree | Prevents unbounded growth | Algorithmic |

**Priority**: #1 and #2 are critical — without them the algorithm pays all the quadtree overhead without getting the algorithmic benefit. #3-#5 are constant-factor improvements that compound nicely on top.
