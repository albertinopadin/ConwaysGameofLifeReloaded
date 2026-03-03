# Swift: Most Performant Way to Pass Large Data Structures in Function Calls

## Research Summary

This document analyzes all available strategies for passing large data structures to functions in Swift, ranked by performance and memory overhead. The analysis covers: compiler-level optimizations, value vs. reference semantics, ownership modifiers, unsafe pointers, and the newest Swift 6.2 features.

---

## Table of Contents

1. [How Swift Actually Passes Parameters (Under the Hood)](#1-how-swift-actually-passes-parameters-under-the-hood)
2. [Strategy Ranking: Fastest to Slowest](#2-strategy-ranking-fastest-to-slowest)
3. [Detailed Analysis of Each Strategy](#3-detailed-analysis-of-each-strategy)
4. [Benchmark Data](#4-benchmark-data)
5. [Decision Matrix](#5-decision-matrix)
6. [Recommendations for ConwaysGameofLifeReloaded](#6-recommendations-for-conwaysgameoflifereloaded)
7. [Sources](#7-sources)

---

## 1. How Swift Actually Passes Parameters (Under the Hood)

### The Compiler's Secret: Large Structs Are Already Passed by Reference

A critical and often-overlooked fact: **the Swift compiler already passes large value types by pointer/address at the SIL (Swift Intermediate Language) level**. A compiler optimization pass rewrites functions that take "big types" to take pointers instead:

- **Before optimization**: `$@convention(method) (BigStruct)`
- **After optimization**: `$@convention(method) (@in_constant BigStruct)`

This was introduced in [Swift PR #8909](https://github.com/apple/swift/pull/8909) and results in:
- **-Onone**: ~3x binary size reduction, ~80% text area reduction
- **-O**: ~2x binary size reduction, ~60% text area reduction

**What this means**: For read-only access to a large struct parameter, the compiler may already optimize away the copy. You don't always need to manually optimize — but you can't *guarantee* the optimizer will do this in all cases (especially with ABI-stable libraries, protocol witnesses, or non-final class methods).

### Two ABI Conventions: Borrowing (+0) vs. Consuming (+1)

Swift uses two conventions for reference-counted parameters:

- **Borrowing (+0)**: The caller guarantees the argument stays alive for the call duration. The callee does NOT need to retain/release. This is the default for most function parameters.
- **Consuming (+1)**: Ownership transfers to the callee, which becomes responsible for releasing. This is the default for initializers and property setters.

The optimizer can switch between these conventions for internal functions, but **cannot** do so for:
- ABI-stable public APIs
- Protocol requirements
- Non-final class methods

This is why explicit ownership modifiers (`borrowing`/`consuming`) exist.

---

## 2. Strategy Ranking: Fastest to Slowest

For **read-only** access to a large data structure:

| Rank | Strategy | Copy? | ARC Overhead? | Safety | Swift Version |
|------|----------|-------|---------------|--------|---------------|
| 1 | `Span` (Swift 6.2) | No | No | Safe | 6.2+ |
| 2 | `borrowing` parameter | No | No (for value types) | Safe | 5.9+ |
| 3 | `inout` parameter | No | No | Safe | All |
| 4 | `~Copyable` (noncopyable) type | No | No | Safe | 5.9+ |
| 5 | `withUnsafeBufferPointer` closure | No | No | Unsafe | All |
| 6 | Class (reference type) | No (pointer copy) | Yes (retain/release) | Safe | All |
| 7 | Default struct parameter (compiler-optimized) | Maybe | Depends | Safe | All |
| 8 | Default struct parameter (unoptimized) | Yes | Yes (if contains refs) | Safe | All |

For **mutation** of a large data structure:

| Rank | Strategy | Copy? | ARC Overhead? | Safety |
|------|----------|-------|---------------|--------|
| 1 | `inout` parameter | No (unique access) | No | Safe |
| 2 | `consuming` + return | Transfer (no copy) | No (for value types) | Safe |
| 3 | `~Copyable` + `inout` | No | No | Safe |
| 4 | `UnsafeMutableBufferPointer` | No | No | Unsafe |
| 5 | Class (reference type) | No | Yes (retain/release) | Safe |

---

## 3. Detailed Analysis of Each Strategy

### 3.1 `Span` (Swift 6.2+) — The New Gold Standard for Read-Only Access

`Span` (SE-0447) provides **safe, zero-copy access** to contiguous memory. It's a non-escapable, non-copyable view into existing storage — essentially a safe `UnsafeBufferPointer`.

```swift
func processData(_ data: Span<Int>) {
    for value in data {
        // Zero-copy, bounds-checked access
    }
}

let array = [1, 2, 3, 4, 5]
processData(array.span)  // No copy, no retain
```

**Why it's fastest**:
- Zero copy — it's just a pointer + length, like C's `const T*`
- No reference counting (non-escapable, so lifetime is compiler-enforced)
- Bounds-checked (unlike `UnsafeBufferPointer`)
- Performance equivalent to unsafe pointers without the safety risks

**Limitations**: Swift 6.2+ only (Xcode 16.3+, released Sept 2025). Read-only access.

### 3.2 `borrowing` Parameter (Swift 5.9+)

Tells the compiler: "I'm borrowing this value. Don't copy it, don't retain it."

```swift
func processGrid(_ grid: borrowing ContiguousArray<ContiguousArray<Cell>>) {
    // grid is borrowed — no copy, no ARC traffic
    let count = grid.count
    // ...
}
```

**Why it's fast**:
- Eliminates unnecessary retain/release for reference types
- Eliminates unnecessary copies for value types
- The compiler guarantees the caller keeps the value alive

**For value types**: No copy occurs — the value is passed by reference (pointer) implicitly.
**For reference types**: No retain/release — the caller guarantees liveness.

**Limitation**: You cannot mutate the parameter or store it beyond the function's scope. Available since Swift 5.9.

### 3.3 `inout` Parameter — The Best Safe Option for Mutation

```swift
func updateCells(_ grid: inout ContiguousArray<ContiguousArray<Cell>>) {
    // Direct mutation, no copy (unique access guaranteed)
    for i in grid.indices {
        grid[i][0].currentState = true
    }
}
```

**Why it's fast**:
- **No copy** — Swift guarantees exclusive access, so no COW trigger
- Direct memory mutation (passed as pointer)
- Works with all Swift versions

**Critical insight from Apple's optimization tips**: Always prefer `inout` for mutating container operations:

```swift
// GOOD — no copy, direct mutation
func append_one(a: inout [Int]) {
    a.append(1)
}

// BAD — triggers COW copy
func append_one(_ a: [Int]) -> [Int] {
    var a = a        // COW copy triggered here
    a.append(1)
    return a
}
```

### 3.4 `~Copyable` (Noncopyable Types, Swift 5.9+)

Types marked `~Copyable` can **never** be copied — they can only be moved or borrowed.

```swift
struct GameGrid: ~Copyable {
    var cells: ContiguousArray<ContiguousArray<Bool>>

    consuming func reset() -> GameGrid {
        // Ownership transferred, original invalidated
        var grid = self  // No copy — this IS self
        for i in grid.cells.indices {
            for j in grid.cells[i].indices {
                grid.cells[i][j] = false
            }
        }
        return grid
    }
}

func processGrid(_ grid: borrowing GameGrid) {
    // Compiler GUARANTEES no copy happens
}
```

**Benchmark data** (from Infinum, processing 2.47GB file):

| Implementation | Time (ms) |
|---|---|
| CChar array | 106,295 |
| Reused allocation | 100,463 |
| Class (reference type) | 3,136 |
| **~Copyable struct** | **2,079** |

The `~Copyable` version was **34% faster than the class** and **51x faster than the naive value type** by eliminating all `swift_retain`/`swift_release` calls.

**Limitation**: Cannot be used with generics that require `Copyable` (including `Optional`, `Array`, etc.) without additional `~Copyable` generic support (SE-0427).

### 3.5 `withUnsafeBufferPointer` — Zero-Copy but Unsafe

```swift
let data: ContiguousArray<Int> = [1, 2, 3, 4, 5]
data.withUnsafeBufferPointer { buffer in
    // buffer is UnsafeBufferPointer<Int> — raw pointer + count
    // Zero copy, no ARC, maximum performance
    for i in 0..<buffer.count {
        process(buffer[i])
    }
}
```

**Why it's fast**: Raw pointer access with no overhead at all.

**Why it's ranked below safe alternatives**: No bounds checking, pointer can dangle if misused. Prefer `Span` (Swift 6.2+) or `borrowing` for the same performance with safety.

### 3.6 Class (Reference Type)

```swift
final class CellGrid {
    var cells: ContiguousArray<ContiguousArray<Cell>>
    // ...
}

func processGrid(_ grid: CellGrid) {
    // Only an 8-byte pointer is passed
    // BUT: retain on entry, release on exit (ARC overhead)
}
```

**Overhead**: Each function call incurs a `swift_retain` on entry and `swift_release` on exit. For hot-path functions called millions of times, this adds up. A class with N reference-type properties has O(1) ARC cost per copy (just the parent pointer), whereas a struct with N reference-type properties has O(N) ARC cost per copy.

**When classes win over structs**: When the struct contains many reference-type properties. A struct with 10 class properties took **5.1 seconds** for 10M copies; with 20 class properties: **14.5 seconds**. The equivalent class: **~1.75 seconds** regardless of inner property count.

### 3.7 Default Struct Parameter (With/Without Optimization)

```swift
struct LargeStruct {
    var a, b, c, d, e, f, g, h: Int  // 64 bytes
}

func processData(_ data: LargeStruct) {
    // Compiler MAY optimize to pass by reference
    // But NO guarantee, especially across module boundaries
}
```

**Key facts**:
- Fully stack-allocated structs (containing only value types): copying is ~O(1) per Apple, extremely fast even for large sizes
- Structs containing reference types: each copy triggers retain for every inner reference (O(N) where N = number of reference-typed properties)
- The compiler's "pass large types by address" optimization helps but isn't guaranteed in all scenarios

### 3.8 `InlineArray` (Swift 6.2+) — Fixed-Size, Stack-Allocated

```swift
let buffer: InlineArray<1024, UInt8> = .init(repeating: 0)
```

**Performance**: 20-30% faster than `Array` for fixed-size buffers. Eliminates heap allocation entirely. Ideal for lookup tables, caches, and buffers of known size.

Not directly a "parameter passing" strategy, but reduces the overhead of the data structure itself, which compounds with any passing strategy.

---

## 4. Benchmark Data Summary

### Noncopyable vs. Class vs. Value Type (2.47GB file processing)

| Approach | Time (ms) | Relative |
|---|---|---|
| Naive value type (String) | DNF | - |
| CChar array | 106,295 | 51x slower |
| Reused allocation | 100,463 | 48x slower |
| Class | 3,136 | 1.5x slower |
| **~Copyable struct** | **2,079** | **1.0x (baseline)** |

### Struct Copy Overhead (10M copies)

| Struct Contents | Copy Time |
|---|---|
| Only value types (stack-allocated) | ~0.005s (1M) |
| 10 class properties | 5.1s |
| 20 class properties | 14.5s |
| Class with same properties | ~1.75s |

### InlineArray vs Array

| Type | Improvement |
|---|---|
| InlineArray | 20-30% faster than Array |

---

## 5. Decision Matrix

### "What should I use?"

```
Is your data read-only in this function?
├── YES
│   ├── Swift 6.2+? → Use Span
│   ├── Swift 5.9+? → Use borrowing parameter
│   └── Older Swift? → Use withUnsafeBufferPointer or class reference
│
└── NO (mutation needed)
    ├── Can you use inout? → Use inout (best option)
    ├── Need to transfer ownership? → Use consuming parameter
    └── Need to prevent all copies? → Use ~Copyable + inout
```

### Special Cases

- **Hot loop called millions of times**: Use `borrowing` or `Span` to eliminate even the ARC retain/release overhead of classes
- **Struct with many reference-type properties**: Consider wrapping in a class, or restructure to reduce reference-type members
- **Fixed-size buffer**: Use `InlineArray` (Swift 6.2+) for stack allocation
- **C interop**: Use `withUnsafeBufferPointer` / `withUnsafeMutableBufferPointer`

---

## 6. Recommendations for ConwaysGameofLifeReloaded

Given this project's architecture (`Cell` is a `final class`, `CellGrid` uses `ContiguousArray<ContiguousArray<Cell>>`):

1. **The grid is already a class-based system** — `Cell` is a reference type, so passing `ContiguousArray<Cell>` already benefits from pointer semantics for the cells themselves. The container (`ContiguousArray`) uses COW.

2. **For `CellGrid.updateCells()`**: The current `DispatchQueue.concurrentPerform` approach works well because each thread accesses its own column slice. No copies occur because:
   - The grid is accessed via `self` (the `CellGrid` instance)
   - `Cell` objects are reference types (only pointers are accessed)

3. **Potential improvements**:
   - Mark read-only grid parameters as `borrowing` (Swift 5.9+) to eliminate any retain/release on `Cell` references during iteration
   - If migrating to a HashLife representation (current branch goal), consider `~Copyable` for the quad-tree nodes to eliminate ARC overhead entirely
   - For bulk cell state arrays (if refactoring away from `Cell` class to pure value types), use `inout` for mutation or `Span` for read-only access

---

## 7. Sources

### Official Swift Documentation & Proposals
- [SE-0377: borrowing and consuming parameter ownership modifiers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md)
- [SE-0390: Noncopyable structs and enums](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md)
- [SE-0427: Noncopyable generics](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0427-noncopyable-generics.md)
- [SE-0447: Span: Safe Access to Contiguous Storage](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0447-span-access-shared-contiguous-storage.md)
- [SE-0453: InlineArray (fixed-size array)](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0453-vector.md)
- [Swift OptimizationTips.rst](https://github.com/swiftlang/swift/blob/main/docs/OptimizationTips.rst)
- [Swift PR #8909: Pass large loadable types by address](https://github.com/apple/swift/pull/8909)
- [Understanding Swift Performance — WWDC 2016](https://developer.apple.com/videos/play/wwdc2016/416/)
- [Unsafe Swift — WWDC 2020](https://developer.apple.com/videos/play/wwdc2020/10648/)
- [Improve memory usage and performance with Swift — WWDC 2025](https://developer.apple.com/videos/play/wwdc2025/312/)

### Articles & Guides
- [A Comprehensive Guide to Understanding Ownership in Swift — Infinum](https://infinum.com/blog/swift-ownership/)
- [Meet Non-Copyable Types: Swift's Secret Performance Boost — Infinum](https://infinum.com/blog/swift-non-copyable-types/)
- [Memory Management and Performance of Value Types — SwiftRocks](https://swiftrocks.com/memory-management-and-performance-of-value-types.html)
- [Swift Adopts Ownership (Kind Of) — Materialized View](https://materializedview.io/p/swift-adds-ownership-kind-of)
- [Swift: consume Operator and Parameter Ownership — Valeriy Van](https://valeriyvan.com/2025/02/10/swift-consume-ownership.html)
- [Almost Manual ARC in Swift: Ownership Modifiers — Mykola Dementiev](https://medium.com/@mykola.dementiev/almost-manual-arc-in-swift-ownership-modifiers-and-lifetime-guarantees-ea73e60b0b78)
- [Understanding Swift Copy-on-Write Mechanisms — Luciano Almeida](https://medium.com/@lucianoalmeida1/understanding-swift-copy-on-write-mechanisms-52ac31d68f2f)
- [Copy on Write and Swift-CowBox Macro — SwiftToolkit](https://www.swifttoolkit.dev/posts/copy-on-write-cowbox)
- [Value Types and Reference Types in Swift — Vadim Bulavin](https://www.vadimbulavin.com/value-types-and-reference-types-in-swift/)
- [Swift Pointers Overview — Vadim Bulavin](https://www.vadimbulavin.com/swift-pointers-overview-unsafe-buffer-raw-and-managed-pointers/)
- [Noncopyable structs and enums — Hacking with Swift](https://www.hackingwithswift.com/swift/5.9/noncopyable-structs-and-enums)
- [What's new in Swift 6.2 — Hacking with Swift](https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2)
- [InlineArray: Fixed-Size Arrays in Swift — Livsy Code](https://livsycode.com/swift/inlinearray-a-fixed-size-arrays-in-swift/)
- [Swift Struct vs Class Performance — Mohit Kumar](https://medium.com/macoclock/swift-struct-vs-class-performance-29b7be73d9fd)
- [WWDC 2025: Improve memory usage and performance with Swift — DEV Community](https://dev.to/arshtechpro/wwdc-2025-improve-memory-usage-and-performance-with-swift-4kbd)

### Swift Forums
- [On the guidance for using a struct versus a class and performance](https://forums.swift.org/t/on-the-guidance-for-using-a-struct-versus-a-class-and-performance/49561)
- [Accepted: SE-0377 borrowing and consuming](https://forums.swift.org/t/accepted-with-modifications-se-0377-borrowing-and-consuming-parameter-ownership-modifiers/62759)
- [Accepted: SE-0453 InlineArray](https://forums.swift.org/t/accepted-with-modifications-se-0453-inlinearray-formerly-vector-a-fixed-size-array/77678)
- [SE-0447: Span discussion](https://forums.swift.org/t/se-0447-span-safe-access-to-contiguous-storage/74676)
