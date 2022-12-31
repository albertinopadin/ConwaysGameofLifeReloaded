//
//  CellGrid.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit


struct Point: Hashable {
    var x: Int = 0
    var y: Int = 0
}


// Using Hashlife algorithm, as described here: https://johnhw.github.io/hashlife/index.md.html
final class QuadTreeNode: Hashable, CustomStringConvertible {
    static let PRIME_A: UInt64 = 5131830419411
    static let PRIME_B: UInt64 = 3758991985019
    static let PRIME_C: UInt64 = 8973110871315
    static let PRIME_D: UInt64 = 4318490180473
    
    static func == (lhs: QuadTreeNode, rhs: QuadTreeNode) -> Bool {
        return lhs.ihash == rhs.ihash
    }
    
    var k: Int
    var a: QuadTreeNode?
    var b: QuadTreeNode?
    var c: QuadTreeNode?
    var d: QuadTreeNode?
    var n: Int
    var ihash: UInt64
    var description: String {
        return "Node k=\(k), \(1<<k) x \(1<<k), pop \(n)"
    }
    
    init(k: Int, a: QuadTreeNode?, b: QuadTreeNode?, c: QuadTreeNode?, d: QuadTreeNode?, n: Int, hash: UInt64) {
        self.k = k
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.n = n
        self.ihash = hash
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ihash)
    }
}


final class CellGrid {
    let xCount: Int
    let yCount: Int
    let halfCountX: Int
    let halfCountY: Int
    final var grid = ContiguousArray<ContiguousArray<Cell>>()   // 2D Array to hold the cells
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    var shadowed = [Cell]()
    final let updateQueue = DispatchQueue(label: "cgol.update.queue",
                                          qos: .userInteractive,
                                          attributes: .concurrent)
    
    final let arrayQueue = DispatchQueue(label: "cgol.array.queue",
                                          qos: .userInteractive)
    
    final let aliveColor: SKColor = .green
    final let deadColor = SKColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    final let shadowColor: SKColor = .darkGray
    
    final let colorAliveAction = SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.3)
    final let colorDeadAction = SKAction.colorize(with: SKColor(red: 0.16,
                                                                 green: 0.15,
                                                                 blue: 0.30,
                                                                 alpha: 1.0),
                                                    colorBlendFactor: 1.0,
                                                    duration: 0.3)
    
    // Hashlife base level nodes:
    final let alive = QuadTreeNode(k: 0, a: nil, b: nil, c: nil, d: nil, n: 1, hash: 1)
    final let dead  = QuadTreeNode(k: 0, a: nil, b: nil, c: nil, d: nil, n: 0, hash: 0)
    
    final var quadTreeHead: QuadTreeNode = QuadTreeNode(k: 0, a: nil, b: nil, c: nil, d: nil, n: 0, hash: 42)
    final var gridPoints = [(Point, Int)]()
//    final let cache = NSCache<NSNumber, QuadTreeNode>()
    final let quadHashCache = NSCache<NSNumber, QuadTreeNode>()
    final let zeroKCache = NSCache<NSNumber, QuadTreeNode>()
    final let successorHashCache = NSCache<NSString, QuadTreeNode>()
    final let initPoint = Point(x: 0, y: 0)
    final var initialPoints: [Point]
    
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        halfCountX = Int(xCells/2)
        halfCountY = Int(yCells/2)
        self.cellSize = cellSize
        initialPoints = [initPoint, Point(x: xCells, y: yCells)]
        quadTreeHead = construct(points: initialPoints)
        gridPoints = expand(node: quadTreeHead)
        grid = makeGrid(xCells: xCells, yCells: yCells)
        setNeighborsForAllCellsInGrid()
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
        
//        cache.setObject(alive, forKey: alive.ihash as NSNumber)
//        cache.setObject(dead, forKey: dead.ihash as NSNumber)
    }
    
    // ---------------- Hashlife functions: ---------------- //
    
    // TODO: Implement cache function as decorator (like in Python)
    @inlinable
    final func getQuadHash(a: QuadTreeNode, b: QuadTreeNode, c: QuadTreeNode, d: QuadTreeNode) -> UInt64 {
        let ak2 = UInt64(a.k + 2)
        // TODO: Perhaps use smaller prime numbers to multiply here:
        // Using overflow operators: https://docs.swift.org/swift-book/LanguageGuide/AdvancedOperators.html
        let amp = a.ihash&*QuadTreeNode.PRIME_A
        let bmp = b.ihash&*QuadTreeNode.PRIME_B
        let cmp = c.ihash&*QuadTreeNode.PRIME_C
        let dmp = d.ihash&*QuadTreeNode.PRIME_D
        let primeMult = ak2 &+ amp &+ bmp &+ cmp &+ dmp
        return primeMult & ((1 << 63) - 1)
    }
    
    @inlinable
    final func join(a: QuadTreeNode, b: QuadTreeNode, c: QuadTreeNode, d: QuadTreeNode) -> QuadTreeNode {
//        print("[join]")
        let newHash = getQuadHash(a: a, b: b, c: c, d: d)
        if let cached = quadHashCache.object(forKey: newHash as NSNumber) {
//            print("[join] HIT CACHE! cached = \(cached)")
            return cached
        } else {
            let n = a.n + b.n + c.n + d.n
            let joined = QuadTreeNode(k: a.k + 1, a: a, b: b, c: c, d: d, n: n, hash: newHash)
//            print("[join] returning new: \(joined)")
            quadHashCache.setObject(joined, forKey: newHash as NSNumber)
            return joined
        }
    }
    
    @inlinable
    final func getZero(k: Int) -> QuadTreeNode {
//        print("[getZero] k = \(k)")
        
        if let cached = zeroKCache.object(forKey: k as NSNumber) {
//            print("[getZero] HIT CACHE! cached: \(cached)")
            return cached
        } else {
//            let zero = (k == 0) ? dead : join(a: getZero(k: k-1), b: getZero(k: k-1), c: getZero(k: k-1), d: getZero(k: k-1))
            var zero: QuadTreeNode
            if k == 0 {
                zero = dead
            } else {
                zero = join(a: getZero(k: k-1), b: getZero(k: k-1), c: getZero(k: k-1), d: getZero(k: k-1))
            }

//            print("[getZero] Returning new zero: \(zero)")

            zeroKCache.setObject(zero, forKey: k as NSNumber)
            return zero
        }
        
//        var zero: QuadTreeNode
//        if k == 0 {
//            zero = dead
//        } else {
//            zero = join(a: getZero(k: k-1), b: getZero(k: k-1), c: getZero(k: k-1), d: getZero(k: k-1))
//        }
//
//        print("[getZero] Returning new zero for k:\(k) : \(zero)")
//
//        return zero
    }
    
    @inlinable
    final func getCenter(m: QuadTreeNode) -> QuadTreeNode {
//        print("[getCenter] with m.k: \(m.k)")
        let z = getZero(k: m.k - 1)
//        let z = getZero(k: m.a!.k)
        return join(a: join(a: z, b: z, c: z, d: m.a!),
                    b: join(a: z, b: z, c: m.b!, d: z),
                    c: join(a: z, b: m.c!, c: z, d: z),
                    d: join(a: m.d!, b: z, c: z, d: z))
    }
    
    // Life rule for 3x3 collection of cells:
    @inlinable
    final func life(a: QuadTreeNode, b: QuadTreeNode, c: QuadTreeNode, d: QuadTreeNode, E: QuadTreeNode,
              f: QuadTreeNode, g: QuadTreeNode, h: QuadTreeNode, i: QuadTreeNode) -> QuadTreeNode {
        let mooreNeighborsLive = [a, b, c, d, f, g, h, i].lazy.filter({ $0?.n == 1 }).count
        return (E.n == 1 && mooreNeighborsLive == 2) || mooreNeighborsLive == 3 ? alive: dead
    }
    
    @inlinable
    final func life4x4(m: QuadTreeNode) -> QuadTreeNode {
        let ad = life(a: m.a!.a!, b: m.a!.b!, c: m.b!.a!, d: m.a!.c!, E: m.a!.d!, f: m.b!.c!, g: m.c!.a!, h: m.c!.b!, i: m.d!.a!)
        let bc = life(a: m.a!.b!, b: m.b!.a!, c: m.b!.b!, d: m.a!.d!, E: m.b!.c!, f: m.b!.d!, g: m.c!.b!, h: m.d!.a!, i: m.d!.b!)
        let cb = life(a: m.a!.c!, b: m.a!.d!, c: m.b!.c!, d: m.c!.a!, E: m.c!.b!, f: m.d!.a!, g: m.c!.c!, h: m.c!.d!, i: m.d!.c!)
        let da = life(a: m.a!.d!, b: m.b!.c!, c: m.b!.d!, d: m.c!.b!, E: m.d!.a!, f: m.d!.b!, g: m.c!.d!, h: m.c!.d!, i: m.d!.d!)
        return join(a: ad, b: bc, c: cb, d: da)
    }
    
    @inlinable
    final func getSuccessorHash(m: QuadTreeNode, j: Int? = nil) -> String {
        return "\(m.ihash)-\(j ?? 0)"
    }
    
    // Return the 2^(k-1) x 2^(k-1) successor, 2^j generations in the future:
    @inlinable
    final func successor(m: QuadTreeNode, j: Int? = nil) -> QuadTreeNode {
//        print("[successor] j = \(String(describing: j))")
        if let cached = successorHashCache.object(forKey: getSuccessorHash(m: m, j: j) as NSString) {
            return cached
        } else {
            let successorNode: QuadTreeNode
            if m.n == 0 {
                successorNode = m.a!
//                print("[successor] Returning m.a")
            } else if m.k == 2 {
                // Base case:
                successorNode = life4x4(m: m)
//                print("[successor] Returning life4x4 of m")
            } else {
//                print("[successor] m.k = \(m.k)")
                let jn: Int
                if let j {
                    jn = min(j, m.k - 2)
                } else {
                    jn = m.k - 2
                }
                
//                print("[successor] Getting c1...")
                let c1 = successor(m: join(a: m.a!.a!, b: m.a!.b!, c: m.a!.c!, d: m.a!.d!), j: jn)
//                print("[successor] Getting c2...")
                let c2 = successor(m: join(a: m.a!.b!, b: m.b!.a!, c: m.a!.d!, d: m.b!.c!), j: jn)
//                print("[successor] Getting c3...")
                let c3 = successor(m: join(a: m.b!.a!, b: m.b!.b!, c: m.b!.c!, d: m.b!.d!), j: jn)
//                print("[successor] Getting c4...")
                let c4 = successor(m: join(a: m.a!.c!, b: m.a!.d!, c: m.c!.a!, d: m.c!.b!), j: jn)
//                print("[successor] Getting c5...")
                let c5 = successor(m: join(a: m.a!.d!, b: m.b!.c!, c: m.c!.b!, d: m.d!.a!), j: jn)
//                print("[successor] Getting c6...")
                let c6 = successor(m: join(a: m.b!.c!, b: m.b!.d!, c: m.d!.a!, d: m.d!.b!), j: jn)
//                print("[successor] Getting c7...")
                let c7 = successor(m: join(a: m.c!.a!, b: m.c!.b!, c: m.c!.c!, d: m.c!.d!), j: jn)
//                print("[successor] Getting c8...")
                let c8 = successor(m: join(a: m.c!.b!, b: m.d!.a!, c: m.c!.d!, d: m.d!.c!), j: jn)
//                print("[successor] Getting c9...")
                let c9 = successor(m: join(a: m.d!.a!, b: m.d!.b!, c: m.d!.c!, d: m.d!.d!), j: jn)
                
//                print("[successor] jn = \(jn)")
                
                if jn < m.k - 2 {
                    successorNode = join(a: join(a: c1.d!, b: c2.c!, c: c4.b!, d: c5.a!),
                                         b: join(a: c2.d!, b: c3.c!, c: c5.b!, d: c6.a!),
                                         c: join(a: c4.d!, b: c5.c!, c: c7.b!, d: c8.a!),
                                         d: join(a: c5.d!, b: c6.c!, c: c8.b!, d: c9.a!))
                } else {
                    successorNode = join(a: successor(m: join(a: c1, b: c2, c: c4, d: c5), j: j),
                                         b: successor(m: join(a: c2, b: c3, c: c5, d: c6), j: j),
                                         c: successor(m: join(a: c4, b: c5, c: c7, d: c8), j: j),
                                         d: successor(m: join(a: c5, b: c6, c: c8, d: c9), j: j))
                }
            }
            
            let shash = getSuccessorHash(m: m, j: j)
            successorHashCache.setObject(successorNode, forKey: shash as NSString)
//            print("[successor] Returning from third case")
            return successorNode
        }
    }
    
    @inlinable
    final func advance(node: QuadTreeNode, n: Int) -> QuadTreeNode {
        if n == 0 {
            return node
        }
        
        // Binary expansion:
        var levels = n
        var _node = node
        var bits = [Int]()
        while levels > 0 {
            bits.append(levels & 1)
            levels = levels >> 1
            _node = getCenter(m: _node)  // Nest
        }
        
        bits.reversed().enumerated().forEach { (k: Int, bit: Int) in
            let j = bits.count - k - 1
            if bit == 1 {
                _node = successor(m: _node, j: j)
            }
        }
        
        return _node
    }
    
    // Pack / unpack data to/from quadtree format:
    /*
     Turn a quadtree a list of (x,y,gray) triples
     in the rectangle (x,y) -> (clip[0], clip[1]) (if clip is not-None).
     If `level` is given, quadtree elements at the given level are given
     as a grayscale level 0.0->1.0,  "zooming out" the display.
    */
    @inlinable
    final func expand(node: QuadTreeNode, x: Int = 0, y: Int = 0,
                      clip: (Int, Int, Int, Int)? = nil, level: Int = 0) ->[(Point, Int)] {
        if node.n == 0 {
            return []
        }
        
        let size = (pow(2, node.k) as NSDecimalNumber).intValue
        
        if let clip = clip {
            if x + size < clip.0 || x > clip.1 || y + size < clip.2 || y > clip.3 {
                return []
            }
        }
        
        if node.k == level {
            // Base case:
            let gray = node.n / (pow(Decimal(size), 2) as NSDecimalNumber).intValue
            return [(Point(x: x >> level, y: y >> level), gray)]
        } else {
            // Return all points contained inside this node:
            let offset = size >> 1
            return  expand(node: node.a!, x: x, y: y, clip: clip, level: level) +
                    expand(node: node.b!, x: x + offset, y: y, clip: clip, level: level) +
                    expand(node: node.c!, x: x, y: y + offset, clip: clip, level: level) +
                    expand(node: node.d!, x: x + offset, y: y + offset, clip: clip, level: level)
        }
    }
    
    // Turn a list of (x,y) coordinates into a quadtree:
    @inlinable
    final func construct(points: [Point]) -> QuadTreeNode {
//        print("[construct] Num points: \(points.count)")
        // Force start at (0, 0)
        guard points.count > 0 else { return dead }
        let minX = points.lazy.map({ $0.x }).min()!
        let minY = points.lazy.map({ $0.y }).min()!
//        print("[construct] Mins: \((minX, minY))")
        
//        print("[construct] Creating pattern...")
//        var pattern = points.reduce(into: [Point: QuadTreeNode]()) {
//            $0[Point(x: $1.x - minX, y: $1.y - minY)] = alive
//        }
        
        var pattern = [Point: QuadTreeNode]()
        for point in points {
            pattern[Point(x: point.x - minX, y: point.y - minY)] = alive
        }
        
        var k = 0
        var lastNode = dead
        
//        print("[construct] Entering while loop...")
        while pattern.count != 1 {
//            print("[construct] Pattern.count: \(pattern.count)")
            
            // Bottom-up construction:
            var nextLevel = [Point: QuadTreeNode]()
            let zero = getZero(k: k)
            print("[construct] zero for k: \(k) = \(zero)")
            
            while !pattern.isEmpty {
//                var patternIter = pattern.makeIterator()
//                if let nxt = patternIter.next() {
                if let nxt = pattern.first {
//                    print("[construct] patternIter.next(): \(nxt)")
                    let point = nxt.key
//                    print("[construct] patternIter point: \(point)")
                    let nPoint = Point(x: point.x - (point.x & 1), y: point.y - (point.y & 1))
//                    print("[construct] nPoint: \(nPoint)")
                    let a = pattern.removeValue(forKey: nPoint) ?? zero
//                    print("[construct] a: \(a)")
                    let b = pattern.removeValue(forKey: Point(x: nPoint.x + 1, y: nPoint.y)) ?? zero
                    let c = pattern.removeValue(forKey: Point(x: nPoint.x, y: nPoint.y + 1)) ?? zero
                    let d = pattern.removeValue(forKey: Point(x: nPoint.x + 1, y: nPoint.y + 1)) ?? zero
                    let lastNodePoint = Point(x: nPoint.x >> 1, y: nPoint.y >> 1)
                    lastNode = join(a: a, b: b, c: c, d: d)
//                    print("[construct] adding node: \(lastNode) for point: \(lastNodePoint)")
                    nextLevel[lastNodePoint] = lastNode
                } else {
                    break
                }
            }
            
            // Merge at next level:
            print("[construct] Merging at next level: \(k+1)")
            pattern = nextLevel
            k += 1
        }
        
        print("[construct] returning...")
        return lastNode
//        return pad(node: lastNode)
    }
    
    @inlinable
    final func isPadded(node: QuadTreeNode) -> Bool {
        let c1: Bool = node.a?.n == node.a?.d?.d?.n
        let c2: Bool = node.b?.n == node.b?.c?.c?.n
        let c3: Bool = node.c?.n == node.c?.b?.b?.n
        let c4: Bool = node.d?.n == node.d?.a?.a?.n
        return c1 && c2 && c3 && c4
    }
    
    @inlinable
    final func pad(node: QuadTreeNode) -> QuadTreeNode {
        if node.k <= 3 || !isPadded(node: node) {
            return pad(node: getCenter(m: node))
        } else {
            return node
        }
    }
    
    // ----------------------------------------------------- //
    
    @inlinable
    final func makeGrid(xCells: Int, yCells: Int) -> ContiguousArray<ContiguousArray<Cell>> {
        let initialCell = Cell(frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                               color: aliveColor,
                               shadowColor: shadowColor,
                               colorAliveAction: colorAliveAction,
                               colorDeadAction: colorDeadAction)
        let newGridRow = ContiguousArray<Cell>(repeating: initialCell, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<Cell>>(repeating: newGridRow, count: xCells)

        for x in 0..<xCells {
            for y in 0..<yCells {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!

                // For adding directly to scene:
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize),
                                       y: cellMiddle(iteration: y, length: cellSize),
                                       width: cellSize,
                                       height: cellSize)

                newGrid[x][y] = Cell(frame: cellFrame,
                                     color: aliveColor,
                                     shadowColor: shadowColor,
                                     colorAliveAction: colorAliveAction,
                                     colorDeadAction: colorDeadAction)
            }
        }
        return newGrid
    }
    
    // Returns the middle coordinate given an iteration and a length
    // Example: If the cell is in iteration 0 and the length of a side
    // of the cell is 4, the cell middle would be 2.
    // Useful to position cells by their center point
    private final func cellMiddle(iteration: Int, length: CGFloat) -> CGFloat {
        return (CGFloat(iteration) * length) + length/2
    }
    
    private func setNeighborsForAllCellsInGrid() {
        for x in 0..<xCount {
            for y in 0..<yCount {
                grid[x][y].neighbors = getCellNeighbors(x: x, y: y)
            }
        }
    }
    
    private func getCellNeighbors(x: Int, y: Int) -> ContiguousArray<Cell> {
        var neighbors = ContiguousArray<Cell>()
        
        // Get the neighbors:
        let leftX   = x - 1
        let rightX  = x + 1
        let topY    = y + 1
        let bottomY = y - 1
        
        let leftNeighbor        = leftX > -1 ? grid[leftX][y] : nil
        let upperLeftNeighbor   = leftX > -1 && topY < yCount ? grid[leftX][topY] : nil
        let upperNeighbor       = topY < yCount ? grid[x][topY] : nil
        let upperRightNeighbor  = rightX < xCount && topY < yCount ? grid[rightX][topY] : nil
        let rightNeighbor       = rightX < xCount ? grid[rightX][y] : nil
        let lowerRightNeighbor  = rightX < xCount && bottomY > -1 ? grid[rightX][bottomY] : nil
        let lowerNeighbor       = bottomY > -1 ? grid[x][bottomY] : nil
        let lowerLeftNeighbor   = leftX > -1 && bottomY > -1 ? grid[leftX][bottomY] : nil
        
        if let left_n = leftNeighbor {
            neighbors.append(left_n)
        }
        
        if let upper_left_n = upperLeftNeighbor {
            neighbors.append(upper_left_n)
        }
        
        if let upper_n = upperNeighbor {
            neighbors.append(upper_n)
        }
        
        if let upper_right_n = upperRightNeighbor {
            neighbors.append(upper_right_n)
        }
        
        if let right_n = rightNeighbor {
            neighbors.append(right_n)
        }
        
        if let lower_right_n = lowerRightNeighbor {
            neighbors.append(lower_right_n)
        }
        
        if let lower_n = lowerNeighbor {
            neighbors.append(lower_n)
        }
        
        if let lower_left_n = lowerLeftNeighbor {
            neighbors.append(lower_left_n)
        }
        
        return neighbors
    }
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    @inlinable
    final func updateCells() -> UInt64 {
        // 20-43 FPS on 200x200 grid:
        // 9-26 FPS, 150-300% CPU on 400x400 grid:
        // With Alpha trick:
        // 38-42 FPS on 200x200
        // 30-42 FPS on 400x400
        // 12-18 FPS on 800x800
        // Prepare update:
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                    self.grid[x][y].prepareUpdate()
//                }
//            }
//        }
//
//        // Update
//        // Doing concurrentPerform on both inner and outer loops doubles FPS:
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                    self.grid[x][y].update()
//                }
//            }
//        }
        
        // Hashlife:
        print("Advancing...")
        quadTreeHead = advance(node: quadTreeHead, n: 1)
        print("Expanding...")
        gridPoints = expand(node: quadTreeHead)
        print("Killing all...")
        killAll()
        gridPoints.lazy.forEach { (point, _) in
//            print("[updateCells] Making live point \(point)")
//            grid[point.x][point.y].makeLive()
            
            // HACK:
            var px: Int
            var py: Int
            
            if point.x >= xCount {
                px = xCount - 1
            } else if point.x < 0 {
                px = 0
            } else {
                px = point.x
            }
            
            if point.y >= yCount {
                py = yCount - 1
            } else if point.y < 0 {
                py = 0
            } else {
                py = point.y
            }
            
            grid[px][py].makeLive()
        }
        
        generation += 1
        return generation
    }

    func getGridIndicesFromPoint(at: CGPoint) -> (x: Int, y: Int) {
        let xIndex = Int(at.x / cellSize)
        let yIndex = Int(at.y / cellSize)
        
        return (xIndex, yIndex)
    }
        
    // TODO: Fix index out of bounds bug here:
    @inlinable
    final func touchedCell(at: CGPoint, gameRunning: Bool, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellSize)
        let y = Int(at.y / cellSize)

        let touchedCell = grid[x][y]
        if !withAltAction && !touchedCell.alive {
            updateQueue.sync(flags: .barrier) {
                if gameRunning {
                    touchedCell.makeLive()
                } else {
                    touchedCell.makeLiveTouched()
                }
            }
        }
        
        if withAltAction && touchedCell.alive {
            updateQueue.sync(flags: .barrier) {
                if gameRunning {
                    touchedCell.makeDead()
                } else {
                    touchedCell.makeDeadTouched()
                }
                
            }
        }
        
        // TODO: Implement this the O(1) way
        // For now will just be a loop:
//        let xLen = grid.count
//        let yLen = grid[0].count
//        for x in 0..<xLen {
//            for y in 0..<yLen {
//                let nthCell = grid[x][y]
//                if nthCell.frame.contains(at) {
//                    if !nthCell.alive {
//                        nthCell.makeLive()
//                    }
//
//                    // Break out of loop as we already found cell that contains the point:
//                    break
//                }
//            }
//        }
    }
    
    // To create spaceships:
    func createPattern(with points: [CGPoint]) {
        for p in points {
            let x = Int(p.x / cellSize)
            let y = Int(p.y / cellSize)

            let touchedCell = grid[x][y]
            touchedCell.makeLive()
        }
    }
    
    func resetShadowed() {
        for cell in shadowed {
            cell.node.color = .blue
        }
        shadowed.removeAll()
    }
    
    func shadowPattern(with points: [CGPoint]) {
        for p in points {
            let x = Int(p.x / cellSize)
            let y = Int(p.y / cellSize)

            let cell = grid[x][y]
            if !cell.alive {
                cell.makeShadow()
                shadowed.append(cell)
            }
        }
    }
    
    func getPointDimensions() -> (CGFloat, CGFloat) {
        return (getPointWidth(), getPointHeight())
    }
    
    func getPointWidth() -> CGFloat {
        return CGFloat(xCount) * cellSize
    }
    
    func getPointHeight() -> CGFloat {
        return CGFloat(yCount) * cellSize
    }
    
    @inlinable
    final func killAll() {
        updateQueue.sync(flags: .barrier) {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeDead()
                }
            }
        }
    }
    
    @inlinable
    final func reset() {
        // Reset the game to initial state with no cells alive:
        killAll()
        quadTreeHead = construct(points: initialPoints)
        gridPoints = expand(node: quadTreeHead)
        generation = 0
    }
    
    func shadowSpaceship(at point: CGPoint, type: SpaceshipType) {
        resetShadowed()
        let spaceshipPoints = spaceshipFactory!.createSpaceship(at: point, type: type)
        shadowPattern(with: spaceshipPoints)
    }
    
    func placeSpaceship(at point: CGPoint, type: SpaceshipType) {
        resetShadowed()
        let spaceshipPoints = spaceshipFactory!.createSpaceship(at: point, type: type)
        createPattern(with: spaceshipPoints)
    }
    
    @inlinable
    final func randomState(liveProbability: Double) {
        print("[randomState]")
        reset()
        if liveProbability == 1.0 {
            makeAllLive()
        } else {
            if liveProbability > 0.0 {
                let liveProb = Int(liveProbability*100)
                var randPoints = [Point]()
                randPoints.reserveCapacity(xCount*yCount)
                
                // TODO: Parallel code does not work
//                updateQueue.sync {
//                    randPoints.withUnsafeMutableBufferPointer { pointsBuffer in
//                        DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                            DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                                let randInt = Int.random(in: 0...100)
//                                if randInt <= liveProb {
//                                    self.grid[x][y].makeLive()
//    //                                arrayQueue.sync(flags: .barrier) {
//    //                                    randPoints.append(Point(x: x, y: y))
//    //                                }
//                                    pointsBuffer[x + y*self.xCount] = Point(x: x, y: y)
//                                }
//                            }
//                        }
//                    }
//                }
                
                for x in 0..<xCount {
                    for y in 0..<yCount {
                        let randInt = Int.random(in: 0...100)
                        if randInt <= liveProb {
                            self.grid[x][y].makeLive()
                            randPoints.append(Point(x: x, y: y))
                        }
                    }
                }
                
//                updateQueue.sync {
//                    print("Constructing quad tree")
//                    quadTreeHead = construct(points: randPoints)
//                    print("Expanding...")
//                    gridPoints = expand(node: quadTreeHead)
//                }
                
                print("Constructing quad tree")
                quadTreeHead = construct(points: randPoints)
                print("Expanding...")
                gridPoints = expand(node: quadTreeHead)
                
            }
        }
    }
    
    final func makeAllLive() {
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeLive()
                }
            }
        }
    }
    
}
