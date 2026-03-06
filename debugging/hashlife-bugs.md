# Hashlife Implementation Bug Analysis

Analysis of bugs in `Hashlife.swift` and `HLNode.swift` causing a display issue where only four vertical stripes of living cells appear between completely dead stripes/sections.

---

## Bug 1: `expand()` produces Z-order, not row-major order (PRIMARY STRIPE CAUSE)

**File**: `Hashlife.swift:100-103`

The `expand` function recursively concatenates all cells of NW, then all of NE, then SW, then SE as flat blocks:

```swift
let top = [node.nw!, node.ne!].flatMap { expand(node: $0) }
let bottom = [node.sw!, node.se!].flatMap { expand(node: $0) }
return top + bottom
```

But `update()` at line 286 reads the bitmap as `lifeBitmap[y*xCount + x]`, expecting **row-major** order. For anything beyond level 1, these don't match. For a 4x4 (level-2) node, expand produces:

```
[nw.nw, nw.ne, nw.sw, nw.se, ne.nw, ne.ne, ne.sw, ne.se, ...]
```

But row-major order requires interleaving rows from left and right sub-quadrants:

```
[nw.nw, nw.ne, ne.nw, ne.ne,   <- row 0: left half + right half
 nw.sw, nw.se, ne.sw, ne.se,   <- row 1: left half + right half
 ...]
```

At the scale of an 800x800 grid, this block-order vs row-major mismatch creates exactly the observed pattern -- vertical stripes where quadrant data is misaligned into the wrong spatial positions.

---

## Bug 2: `construct()` NE quadrant reads wrong grid region

**File**: `Hashlife.swift:66-67`

```swift
let neStartY = nwEndY           // BUG: should be yStart
let neEndY = neStartY + yCount  // cascading error
```

NE is the **top-right** quadrant -- it should share the same Y range as NW (top half) but use the right half of X. Instead, `neStartY = nwEndY` places it in the **bottom** half, making NE read the same grid region as SE. The top-right quadrant of the grid is never read; the bottom-right is read twice.

---

## Bug 3: `join()` uses `key.hashValue` as dictionary key -- hash collisions

**File**: `Hashlife.swift:200-206`

```swift
if let existing = canonicalNodes[key.hashValue] {
    return existing
}
let node = HLNode(level: nw.level + 1, id: key.hashValue, nw: nw, ne: ne, sw: sw, se: se)
canonicalNodes[key.hashValue] = node
```

`canonicalNodes` is `[Int: HLNode]` keyed by `hashValue`, but different `NodeKey` values can produce the **same** `hashValue`. When a collision occurs, `join` silently returns the **wrong cached node**. The dictionary should be `[NodeKey: HLNode]` using the struct itself (which is `Hashable`) as the key.

---

## Bug 4: Mutation of shared canonical nodes

**File**: `Hashlife.swift:149` (`applyLifeRules`)

```swift
node.population = alive ? 1 : 0  // mutates the node in place
return node
```

**File**: `Hashlife.swift:117-120` (`synchronizeState`)

```swift
node.nw!.population = grid[xStart][yStart].alive ? 1 : 0
node.ne!.population = grid[xStart + 1][yStart].alive ? 1 : 0
node.sw!.population = grid[xStart][yStart + 1].alive ? 1 : 0
node.se!.population = grid[xStart + 1][yStart + 1].alive ? 1 : 0
```

Hashlife depends on **immutable** canonical nodes. `Hashlife.alive` and `Hashlife.dead` are shared singletons. If `synchronizeState` sets `Hashlife.dead.population = 1`, every node in the entire tree that references `dead` is now corrupted. Similarly, `applyLifeRules` mutates level-0 nodes that may be shared across the tree via canonical deduplication.

---

## Bug 5: Grid axis transposition

**File**: `Hashlife.swift:284-286` (`update`)

```swift
DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    for (x, cell) in self.grid[y].enumerated() {
        cell.nextState = lifeBitmap[y*xCount + x]
```

In `update()`, `grid[y]` is iterated with y as the first index (row). But in `construct()` (lines 46-49), the grid is accessed as `grid[xStart][yStart]` -- using "x" as the first index. If the grid's first dimension is rows (y), then `construct` builds the tree with transposed coordinates.

---

## Fix Options for Bug 1: `expand()` ordering

### Option A: Return 2D array, interleave rows

Change `expand` to return `[[Bool]]` (array of rows), then zip left/right halves together:

```swift
func expand(node: HLNode) -> [[Bool]] {
    if node.level == 0 { return [[node.population == 1]] }

    let topRows = zip(expand(node: node.nw!), expand(node: node.ne!)).map { $0 + $1 }
    let bottomRows = zip(expand(node: node.sw!), expand(node: node.se!)).map { $0 + $1 }
    return topRows + bottomRows
}
```

Flatten at the call site with `.flatMap { $0 }`. Simple and readable, but creates many intermediate arrays.

### Option B: Keep flat `[Bool]`, interleave using computed width

Keep the flat return type but interleave NW/NE and SW/SE row-by-row using the known half-width (`2^(level-1)`):

```swift
let halfWidth = 1 << (node.level - 1)
for row in 0..<halfWidth {
    result.append(contentsOf: nw[(row * halfWidth)..<((row + 1) * halfWidth)])
    result.append(contentsOf: ne[(row * halfWidth)..<((row + 1) * halfWidth)])
}
// same for sw/se
```

More code but avoids nested arrays. Still allocates intermediate flat arrays for each quadrant.

### Option C: Walk the tree directly, skip `expand` entirely (RECOMMENDED)

Eliminate the intermediate bitmap. Recursively traverse the tree and write directly to the grid cells:

```swift
func writeToGrid(node: HLNode, xStart: Int, yStart: Int, size: Int) {
    if node.level == 0 {
        grid[yStart][xStart].nextState = node.population == 1
        return
    }
    let half = size / 2
    writeToGrid(node: node.nw!, xStart: xStart,        yStart: yStart,        size: half)
    writeToGrid(node: node.ne!, xStart: xStart + half,  yStart: yStart,        size: half)
    writeToGrid(node: node.sw!, xStart: xStart,         yStart: yStart + half, size: half)
    writeToGrid(node: node.se!, xStart: xStart + half,  yStart: yStart + half, size: half)
}
```

No intermediate array at all. Coordinates are explicit so no ordering ambiguity. Most cache-friendly for the grid since it writes directly. Also removes the entire class of ordering bugs. Aligns with the codebase's performance-oriented philosophy.

### Option D: Fix the read side with Z-order indexing

Leave `expand` as-is, change `update()` to convert `(x, y)` to a Z-order (Morton code) index when reading the bitmap. Least invasive change but adds per-cell computation overhead and is harder to reason about.

---

## Summary

| Bug | Severity | Effect |
|-----|----------|--------|
| 1. `expand()` ordering | **Critical** | Direct cause of the vertical stripe display pattern |
| 2. `construct()` NE coords | **Critical** | Duplicates bottom-right quadrant data into top-right |
| 3. `join()` hash collisions | **High** | Returns wrong cached nodes on collision |
| 4. Node mutation | **High** | Corrupts shared singleton nodes across entire tree |
| 5. Axis transposition | **Medium** | Tree built with swapped x/y relative to display |
