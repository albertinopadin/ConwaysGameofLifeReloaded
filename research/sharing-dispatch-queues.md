# Swift: Sharing DispatchQueues Between Parent and Child Objects

## Summary

Passing a `DispatchQueue` via initializer injection is a common and valid pattern in Swift. `DispatchQueue` is a class (reference type), so passing it is just an 8-byte pointer — zero performance overhead.

The key concern is **design correctness**, not performance.

---

## The Deadlock Risk

If a parent and child both call `.sync` on the **same serial queue**, and the parent's `.sync` block invokes the child (which also calls `.sync`), you get a deadlock:

```swift
// DEADLOCK EXAMPLE:
class Parent {
    let queue = DispatchQueue(label: "shared.queue")
    let child: Child

    func doWork() {
        queue.sync {                          // Holds the queue
            child.doChildWork()               // Child tries to acquire the same queue
        }
    }
}

class Child {
    let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func doChildWork() {
        queue.sync {                          // DEADLOCK — queue already held by parent
            // ...
        }
    }
}
```

The outer `.sync` holds the serial queue. The inner `.sync` waits for it forever.

---

## Safe Patterns

### Pattern A: Only One Object Calls `.sync`

The parent calls `.sync`, the child just does the work without wrapping in `.sync`:

```swift
class Algorithm {
    // No queue ownership — just does the work
    func update(grid: ContiguousArray<ContiguousArray<Cell>>, xCount: Int) {
        DispatchQueue.concurrentPerform(iterations: xCount) { x in
            grid[x].forEach { $0.prepareUpdate() }
        }
        DispatchQueue.concurrentPerform(iterations: xCount) { x in
            grid[x].lazy.filter({ $0.needsUpdate() }).forEach { $0.update() }
        }
    }
}

class CellGrid {
    let updateQueue = DispatchQueue(label: "cgol.update.queue", qos: .userInteractive)
    let algorithm = Algorithm()

    func updateCells() {
        updateQueue.sync {
            algorithm.update(grid: grid, xCount: xCount)
        }
    }
}
```

**This is the cleanest design.** The algorithm doesn't know about synchronization. The parent owns the queue and decides when to serialize.

### Pattern B: Shared Queue, Parent Calls Child Outside Its Own `.sync`

```swift
// Parent does NOT wrap the call in queue.sync:
let result = algorithm.naiveConcurrent(grid: grid, ...)
// The algorithm internally does queue.sync { ... }
// No nesting — safe
```

This works but couples the child to the queue's synchronization policy.

### Pattern C: Use a Concurrent Queue with Barriers

If both objects need independent access but must coordinate for writes:

```swift
let sharedQueue = DispatchQueue(label: "shared.queue", attributes: .concurrent)

// Reads (concurrent, non-blocking):
sharedQueue.sync {
    // read data
}

// Writes (exclusive via barrier):
sharedQueue.async(flags: .barrier) {
    // mutate data
}
```

---

## Decision Matrix

| Approach | Deadlock Safe? | Clean Design? | Best For |
|----------|---------------|---------------|----------|
| Shared queue, both call `.sync` | No | No | Never do this |
| Shared queue, only parent calls `.sync` | Yes | Yes | Most cases |
| Child has no queue, parent owns sync | Yes | Best | Algorithm objects |
| Concurrent queue with barriers | Yes | Moderate | Reader-writer patterns |

---

## Recommendation for Game of Life

The algorithm classes (`NaiveConcurrent`, future HashLife, etc.) should **not own a queue**. They should be pure computation:

- Accept the grid as a parameter
- Use `DispatchQueue.concurrentPerform` for parallelism (this is a static method, no queue instance needed)
- Return the result

The parent (`CellGrid`) owns the `updateQueue` and wraps calls to the algorithm in `updateQueue.sync { ... }`. This keeps synchronization in one place and makes the algorithms simpler and more testable.
