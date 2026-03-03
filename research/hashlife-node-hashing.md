# HashLife Node Hashing & Canonicalization Research

## The Core Problem

In HashLife, nodes are immutable quadtree cells. The entire algorithm's speedup depends on
**canonicalization** (aka **hash consing**): ensuring that only one instance of each unique
node configuration exists in memory. This enables:

1. **O(1) equality checks** via pointer/reference equality (instead of deep structural comparison)
2. **Memoization** of the `nextGeneration()` function (keyed by node identity)
3. **Space compression** (all empty regions share one canonical empty node)

## How Hash Consing Works

Hash consing is a two-phase approach:

### Phase 1: Structural Hashing (for lookup)
When constructing a new node from four children, compute a hash from the children's identities.
This hash is used to look up whether an equivalent node already exists in a global hash table.

### Phase 2: Pointer Equality (after canonicalization)
Once all nodes are canonicalized (interned), two nodes are equal **if and only if** they are
the same object in memory. This means `===` in Swift, `==` in Java (reference equality),
or pointer comparison in C.

**Key insight**: You hash to *find* canonical nodes, but once found, equality is just pointer
comparison. The hash function is only used during the interning/lookup process.

## Leaf Nodes

Leaf nodes (level 0) represent a single cell — alive or dead. There are exactly **two**
canonical leaf nodes in the entire system:

```
on  = HLNode(level: 0, population: 1)  // alive
off = HLNode(level: 0, population: 0)  // dead
```

These are pre-created singletons. Their hash can be trivially their population (0 or 1).

## Internal Nodes

Internal nodes at level `k` represent a 2^k x 2^k grid. They have four children, each at
level `k-1`. The hash of an internal node is computed from its four children's hashes (or
identities).

## Reference Implementations

### Python (johnhw/hashlife) — Cleanest Reference

```python
on = Node(k=0, n=1, hash=1)
off = Node(k=0, n=0, hash=0)

mask = (1 << 63) - 1

@lru_cache(maxsize=2**24)
def join(a, b, c, d):
    """Combine four children at level k-1 to a new node at level k."""
    n = a.n + b.n + c.n + d.n
    nhash = (
        a.k + 2
        + 5131830419411 * a.hash
        + 3758991985019 * b.hash
        + 8973110871315 * c.hash
        + 4318490180473 * d.hash
    ) & mask
    return Node(a.k+1, n, nhash, a, b, c, d)
```

Key points:
- Hash is **precomputed once** at construction time and stored in the node
- The `@lru_cache` on `join()` IS the canonicalization — same inputs → same cached output
- Hash mixes children's hashes with large prime multipliers, masked to 63 bits
- Level is mixed in to prevent collisions across levels

### Java (Rokicki / Dr. Dobb's) — The Classic Reference

```java
// hashCode(): for leaf nodes, return population; for internal nodes,
// combine System.identityHashCode of children with prime multipliers
public int hashCode() {
    if (level == 0) return (int) population;
    return System.identityHashCode(nw) +
           11 * System.identityHashCode(ne) +
           101 * System.identityHashCode(sw) +
           1007 * System.identityHashCode(se);
}

// equals(): for leaf nodes, compare alive flag;
// for internal nodes, compare children by REFERENCE (==, not .equals())
public boolean equals(Object o) {
    TreeNode t = (TreeNode) o;
    if (level != t.level) return false;
    if (level == 0) return alive == t.alive;
    return nw == t.nw && ne == t.ne && sw == t.sw && se == t.se;
}

// intern(): look up in global HashMap, return existing or insert self
public TreeNode intern() {
    TreeNode result = cache.get(this);
    if (result != null) return result;
    cache.put(this, this);
    return this;
}
```

Key points:
- `hashCode()` uses `System.identityHashCode()` (memory address hash) of children
- `equals()` uses `==` (reference equality) on children, NOT `.equals()`
- This works because children are ALREADY canonicalized when a parent is created
- `intern()` is the canonicalization step — called on every newly created node

### C (dotat.at/hashlife.c) — Minimal Reference

```c
// Two pre-allocated leaf nodes — identity encodes state
static struct square sq_0[2];  // sq_0[0] = dead, sq_0[1] = alive

static inline bool alive(square sq) {
    return (sq - sq_0);  // pointer arithmetic!
}

// find() implements hash consing with cuckoo hashing
static square find(square nw, square ne, square sw, square se);
```

The C version hashes the four child POINTERS directly. No level or population in the hash —
just the four memory addresses.

## What's Wrong With the Current Swift Implementation

The current `HLNode.swift` has two critical bugs:

### Bug 1: `==` compares `hashValue` instead of structure

```swift
public static func == (lhs: HLNode, rhs: HLNode) -> Bool {
    return lhs.hashValue == rhs.hashValue  // WRONG!
}
```

Hash collisions mean two different nodes can have the same `hashValue`. This would cause
the algorithm to incorrectly merge distinct patterns. The `==` operator MUST NOT rely on
`hashValue` for equality — it must compare the actual structure.

### Bug 2: Recursive structural hashing (no canonicalization)

```swift
public func hash(into hasher: inout Hasher) {
    hasher.combine(self.ne)
    hasher.combine(self.nw)
    hasher.combine(self.se)
    hasher.combine(self.sw)
}
```

This recursively hashes child nodes, which recursively hashes THEIR children, etc. For a
level-20 tree this would be astronomically expensive. The whole point of hash consing is that
you hash the children's identities (pointers), not their full structures.

### Bug 3: No leaf node distinction

Leaf nodes (level 0) have `nil` children. With the current hash, ALL leaf nodes hash to the
same value (combining four nils), so alive and dead cells would be indistinguishable.

### Bug 4: No canonicalization mechanism

There's no intern table / hash set to ensure only one instance of each unique node exists.
Without this, the entire HashLife algorithm cannot work.

## Correct Approach for Swift

### Option A: ObjectIdentifier-based (pointer identity hashing)

After canonicalization, use `ObjectIdentifier` to hash based on object identity:

```swift
// For the hash function used during canonicalization lookup:
// Hash the ObjectIdentifiers of the four children
public func hash(into hasher: inout Hasher) {
    if level == 0 {
        hasher.combine(population)
    } else {
        hasher.combine(ObjectIdentifier(nw!))
        hasher.combine(ObjectIdentifier(ne!))
        hasher.combine(ObjectIdentifier(sw!))
        hasher.combine(ObjectIdentifier(se!))
    }
}

// Equality: pointer comparison on children (they're already canonical)
public static func == (lhs: HLNode, rhs: HLNode) -> Bool {
    if lhs.level != rhs.level { return false }
    if lhs.level == 0 { return lhs.population == rhs.population }
    return lhs.nw === rhs.nw && lhs.ne === rhs.ne &&
           lhs.sw === rhs.sw && lhs.se === rhs.se
}
```

This is the Swift equivalent of Java's `System.identityHashCode()` approach.

### Option B: Precomputed custom hash (like the Python version)

Compute the hash once at construction and store it:

```swift
let storedHash: Int

init(...) {
    // ... set children ...
    if level == 0 {
        self.storedHash = Int(population)
    } else {
        // Mix children's stored hashes with large primes
        self.storedHash = Int(level) &+ 2
            &+ 5131830419411 &* nw!.storedHash
            &+ 3758991985019 &* ne!.storedHash
            &+ 8973110871315 &* sw!.storedHash
            &+ 4318490180473 &* se!.storedHash
    }
}

func hash(into hasher: inout Hasher) {
    hasher.combine(storedHash)
}
```

This avoids recursive hash computation entirely — each node's hash is O(1) after construction.

### The Canonicalization Table

Either way, you need a global intern table:

```swift
// In the Hashlife class:
private var canonicalNodes: [HLNode: HLNode] = [:]  // or Set<HLNode>

func intern(_ node: HLNode) -> HLNode {
    if let existing = canonicalNodes[node] {
        return existing
    }
    canonicalNodes[node] = node
    return node
}
```

Every node creation goes through `intern()`. This guarantees uniqueness.

### Recommendation

**Option B (precomputed hash) is preferred** because:
1. It avoids hashing `ObjectIdentifier` which rehashes on every lookup
2. The hash is computed once and stored — O(1) for all future hash calls
3. It matches the approach used by the most performant reference implementations
4. It works naturally with Swift's `Hasher` (just combine the precomputed value)

After canonicalization, equality can use `===` (pointer equality) for maximum performance
in hot paths, while the `==` operator does structural comparison for the intern table lookup.

## Follow-up: Why `level + 2` in the Hash Seed?

In the Python reference implementation's hash formula:

```python
nhash = (a.k + 2 + 5131830419411 * a.hash + ...) & mask
```

The `+ 2` is a practical collision avoidance seed. Leaf hashes are 0 (dead) and 1 (alive).
Without the offset, a node built from four dead leaves (all hash 0) would hash to:

```
level_1 + 0*prime + 0*prime + 0*prime + 0*prime = 1
```

That collides with the alive leaf (hash = 1). By adding `+ 2`, a level-1 all-dead node
hashes to `1 + 2 = 3`, which avoids collision with both leaf values. Any constant >= 2
would work — the choice is arbitrary, not mathematically significant.

## Follow-up: Allocation-Free Intern Lookup in Swift

The Java reference creates a full `TreeNode` to call `intern()`, discarding it if a match
exists. Java's generational GC with bump allocation makes this cheap. In Swift with ARC,
every `HLNode` allocation means:

- Heap allocation
- Reference count initialization
- 4 child reference increments (ARC retain)
- If duplicate: 4 decrements + deallocation

Since the hot path is "look up, already exists, return canonical" — this is wasteful.

### Solution: Lightweight Lookup Key Struct

Use a stack-allocated value type for the intern table key, avoiding `HLNode` allocation
entirely on cache hits:

```swift
/// Stack-allocated, zero-ARC-overhead lookup key for the intern table.
/// Uses ObjectIdentifier (pointer-width integer) for child identity.
struct NodeKey: Hashable {
    let nw: ObjectIdentifier
    let ne: ObjectIdentifier
    let sw: ObjectIdentifier
    let se: ObjectIdentifier

    static func == (lhs: NodeKey, rhs: NodeKey) -> Bool {
        return lhs.nw == rhs.nw && lhs.ne == rhs.ne &&
               lhs.sw == rhs.sw && lhs.se == rhs.se
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nw)
        hasher.combine(ne)
        hasher.combine(sw)
        hasher.combine(se)
    }
}
```

The intern table becomes `[NodeKey: HLNode]`, and the join/canonicalize function:

```swift
private var internTable: [NodeKey: HLNode] = [:]

func join(nw: HLNode, ne: HLNode, sw: HLNode, se: HLNode) -> HLNode {
    let key = NodeKey(
        nw: ObjectIdentifier(nw),
        ne: ObjectIdentifier(ne),
        sw: ObjectIdentifier(sw),
        se: ObjectIdentifier(se)
    )
    if let existing = internTable[key] {
        return existing  // No HLNode allocated!
    }
    let node = HLNode(nw: nw, ne: ne, sw: sw, se: se, level: nw.level + 1)
    internTable[key] = node
    return node
}
```

`ObjectIdentifier` is a pointer-width integer wrapper — no ARC overhead. `NodeKey` is a
struct (stack allocated, no heap). Probing the table on cache hits costs **zero heap
allocations**. An `HLNode` is only instantiated when genuinely new.

This matters because the intern table is hit on every `join()` and every `nextGeneration()`
subdivision — the overwhelming majority of lookups are cache hits.

## Follow-up: Why Level Is in the Python Hash but Not Needed in NodeKey

The Python reference uses a **structural/content hash** — computed recursively from children's
stored hash values, which are pure numbers with no connection to object identity. Without the
level term, cross-level collisions occur:

- Dead leaf: `hash = 0`
- Level-1 node with four dead leaves: `0 * prime + 0 * prime + ... = 0` (same!)
- Level-2 node with four all-dead children: cascades to 0 again

The `a.k + 2` seed breaks this chain by giving each level a distinct baseline.

In the `ObjectIdentifier`-based `NodeKey`, this is a non-issue. The dead leaf and a level-1
all-dead node are different objects at different memory addresses — their `ObjectIdentifier`s
are inherently different values. Level is implicit in the pointer identity.

**In short**: structural hashes need explicit level mixing because the hash values carry no
identity. Pointer/identity-based keys don't, because the pointers already distinguish objects
across levels. This is one reason to favor the `NodeKey`/`ObjectIdentifier` approach — it
sidesteps an entire class of hash collision concerns.

## Follow-up: ObjectIdentifier NodeKey vs Precomputed Hash — Performance Tradeoff

### Per-Lookup Cost Comparison

**Pure ObjectIdentifier NodeKey**:
- `hash(into:)` calls `hasher.combine()` 4 times (once per `ObjectIdentifier`)
- Swift's `Hasher` uses SipHash-1-3 internally; each combine is several arithmetic ops
  (rotations, XORs, additions)
- This cost is paid on every intern table lookup
- Equality: 4 pointer comparisons (very fast, and only triggered on hash bucket match)

**Precomputed structural hash for lookup**:
- Must first compute the hash from children's stored hashes: 4 multiplications + 4 additions
- `hash(into:)` calls `hasher.combine()` once with a single `Int`
- Still needs `ObjectIdentifier`s in the key struct for equality (hash collisions exist)
- Equality: same 4 pointer comparisons

The raw hashing cost is roughly comparable — 4x SipHash combines vs 4 multiplications + 4
additions + 1 SipHash combine.

### The Hybrid Approach (Recommended)

Combine both: precompute the structural hash AND use `ObjectIdentifier`s for equality:

```swift
struct NodeLookupKey: Hashable {
    let precomputedHash: Int
    let nw: ObjectIdentifier
    let ne: ObjectIdentifier
    let sw: ObjectIdentifier
    let se: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(precomputedHash)  // 1 combine call, not 4
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.nw == rhs.nw && lhs.ne == rhs.ne &&
               lhs.sw == rhs.sw && lhs.se == rhs.se
    }
}
```

The join function computes the hash once and reuses it:

```swift
func join(nw: HLNode, ne: HLNode, sw: HLNode, se: HLNode) -> HLNode {
    let hash = HLNode.computeHash(nw: nw, ne: ne, sw: sw, se: se)
    let key = NodeLookupKey(
        precomputedHash: hash,
        nw: ObjectIdentifier(nw),
        ne: ObjectIdentifier(ne),
        sw: ObjectIdentifier(sw),
        se: ObjectIdentifier(se)
    )
    if let existing = internTable[key] {
        return existing  // Zero heap allocation
    }
    let node = HLNode(nw: nw, ne: ne, sw: sw, se: se,
                      level: nw.level + 1, storedHash: hash)  // Reuse hash!
    internTable[key] = node
    return node
}
```

### Why Hybrid Wins

1. **Cache hit path** (the hot path — vast majority of lookups): 1 SipHash combine instead
   of 4. The precomputed hash is a single `Int` already sitting in the struct.
2. **Cache miss path**: the already-computed hash is passed to the `HLNode` constructor,
   avoiding double computation. The node stores it for when it later becomes someone else's
   child.
3. **Zero heap allocation** on cache hits — same as pure `NodeKey`.
4. **Equality** still uses `ObjectIdentifier` pointer comparison — O(1) and correct.

### Practical Impact

The difference between 1 vs 4 `hasher.combine()` calls is likely nanoseconds per lookup.
The dominant performance win of all three approaches (pure ObjectIdentifier, precomputed,
hybrid) is zero heap allocation on cache hits. The real bottleneck is more likely Dictionary
overhead (cache line misses, bucket probing) than the hash function itself. Profiling is
needed to determine if the distinction matters in practice.

## URLs Visited

- https://johnhw.github.io/hashlife/index.md.html — John Googler's HashLife tutorial with Python implementation
- https://en.wikipedia.org/wiki/Hashlife — Wikipedia HashLife article
- https://www.dev-mind.blog/hashlife/ — Dev Mind HashLife explanation
- https://www.drdobbs.com/jvm/an-algorithm-for-compressing-space-and-t/184406478 — Tomas Rokicki's Dr. Dobb's article (original)
- https://conwaylife.com/wiki/HashLife — LifeWiki HashLife page
- https://github.com/mafm/HashLife — Rokicki's Java reference implementation (GitHub mirror)
- https://github.com/johnhw/hashlife — Python reference implementation
- https://github.com/pvwoods/conway-hash-js — JavaScript implementation
- https://github.com/farhiongit/hashlife — C implementation
- https://github.com/Lysxia/hashislife — Another C implementation
- https://github.com/llGaetanll/hashlife — Rust implementation
- https://github.com/luiswirth/lifeash — Rust HashLife (lifeash)
- https://docs.rs/hashlife/latest/hashlife/struct.Node.html — Rust hashlife crate Node docs
- https://dotat.at/prog/life/hashlife.c — Tony Finch's C hashlife source
- https://dotat.at/@/2008-02-12-hashlife.html — Tony Finch's hashlife blog post
- https://golly.sourceforge.io/Help/Algorithms/HashLife.html — Golly HashLife documentation
- https://en.wikipedia.org/wiki/Hash_consing — Hash consing technique (Wikipedia)
- https://grokipedia.com/page/hash_consing — Hash consing explanation
- https://grokipedia.com/page/Hashlife — Grokipedia HashLife
- https://eighty-twenty.org/2011/11/22/equality-hashing-and-canonicalization — Equality, Hashing and Canonicalization
- https://forums.swift.org/t/identity-based-object-hash/4186 — Swift Forums: identity-based hashing
- https://swiftrocks.com/understanding-swifts-objectidentifier — Understanding Swift's ObjectIdentifier
- https://www.swiftbysundell.com/articles/identifying-objects-in-swift/ — Identifying Objects in Swift
- https://developer.apple.com/documentation/swift/objectidentifier/3018232-hash — Apple docs: ObjectIdentifier.hash(into:)
- https://github.com/onmyway133/blog/issues/606 — How to conform to Hashable for class in Swift
- https://raw.githubusercontent.com/johnhw/hashlife/master/hashlife.py — Full Python source
- https://raw.githubusercontent.com/mafm/HashLife/master/java/CanonicalTreeNode.java — Java CanonicalTreeNode source
- https://raw.githubusercontent.com/mafm/HashLife/master/java/TreeNode.java — Java TreeNode source
- https://raw.githubusercontent.com/mafm/HashLife/master/java/TreeNodeBase.java — Java TreeNodeBase source
- https://fpgacpu.ca/writings/HashLife-GPU.pdf — HashLife on GPU paper
- https://www.gathering4gardner.org/g4g13gift/math/RokickiTomas-GiftExchange-LifeAlgorithms-G4G13.pdf — Rokicki Life Algorithms paper
- http://www.thelowlyprogrammer.com/2011/05/game-of-life-part-2-hashlife.html — The Lowly Programmer HashLife tutorial
- https://fanf.livejournal.com/83709.html — Tony Finch LiveJournal HashLife post
- https://github.com/rharel/node-gol-hashlife — Node.js HashLife implementation
