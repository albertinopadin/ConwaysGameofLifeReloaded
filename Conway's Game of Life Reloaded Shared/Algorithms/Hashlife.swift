//
//  Hashlife.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 3/2/26.
//  Copyright © 2026 Albertino Padin. All rights reserved.
//

import Foundation

public final class Hashlife: LifeAlgorithm {
    let updateQueue: DispatchQueue  // Note: if both this and CellGrid call sync on this queue might deadlock
    
    private static var canonicalNodes: [Int: HLNode] = [:]
    
    public static let alive = HLNode(level: 0, id: 1, population: 1)
    public static let dead  = HLNode(level: 0, id: 0, population: 0)
    
    let xCount: Int
    let yCount: Int
    let grid: ContiguousArray<ContiguousArray<Cell>>
    
    var root: HLNode  // Is this right???
    
    init(grid: ContiguousArray<ContiguousArray<Cell>>, xCount: Int, yCount: Int, queue: DispatchQueue) {
        self.grid = grid
        self.xCount = xCount
        self.yCount = yCount
        self.updateQueue = queue
        
        Self.canonicalNodes[Self.dead.id] = Self.dead
        Self.canonicalNodes[Self.alive.id] = Self.alive
        
        self.root = Self.construct(grid: grid, xStart: 0, xEnd: xCount, yStart: 0, yEnd: yCount)
        print("[Hashlife init] Root level: \(self.root.level)")
    }
    
    private static func construct(grid: ContiguousArray<ContiguousArray<Cell>>,
                                  xStart: Int,
                                  xEnd: Int,
                                  yStart: Int,
                                  yEnd: Int) -> HLNode {
//        print("[constructHelper] xStart: \(xStart), xEnd: \(xEnd), yStart: \(yStart), yEnd: \(yEnd)")
        
        if xEnd - xStart == 2 {
            let nw = HLNode(level: 0, population: grid[xStart][yStart].alive ? 1 : 0)
            let ne = HLNode(level: 0, population: grid[xStart + 1][yStart].alive ? 1 : 0)
            let sw = HLNode(level: 0, population: grid[xStart][yStart + 1].alive ? 1 : 0)
            let se = HLNode(level: 0, population: grid[xStart + 1][yStart + 1].alive ? 1 : 0)
            return join(nw: nw, ne: ne, sw: sw, se: se)
        }
        
        let xCount = Int((xEnd - xStart) / 2)
        let yCount = Int((yEnd - yStart) / 2)
        
        let nwStartX = xStart
        let nwEndX = xStart + xCount
        let nwStartY = yStart
        let nwEndY = yStart + yCount
//        let cellsSliceNW = grid[(nwStartX as! C.Index)..<(nwEndX as! C.Index)][(nwStartY as! C.Index)..<(nwEndY as! C.Index)]
        
        let nw = construct(grid: grid, xStart: nwStartX, xEnd: nwEndX, yStart: nwStartY, yEnd: nwEndY)
        
        let neStartX = nwEndX
        let neEndX = neStartX + xCount
        let neStartY = yStart
        let neEndY = neStartY + yCount
//        let cellsSliceNE = grid[(neStartX as! C.Index)..<(neEndX as! C.Index)][(neStartY as! C.Index)..<(neEndY as! C.Index)]
        
        let ne = construct(grid: grid, xStart: neStartX, xEnd: neEndX, yStart: neStartY, yEnd: neEndY)
        
        let swStartX = nwStartX
        let swEndX = swStartX + xCount
        let swStartY = nwEndY
        let swEndY = swStartY + yCount
        
//        print("[constructHelper] swStartX: \(swStartX), swEndX: \(swEndX), swStartY: \(swStartY), swEndY: \(swEndY)")
//        print("[constructHelper] grid count: \(grid.count), grid[0].count: \(grid[0 as! C.Index].count), start: \(grid.startIndex), end: \(grid.endIndex)")
        
//        let cellsSliceSW = grid[(swStartX as! C.Index)..<(swEndX as! C.Index)][(swStartY as! C.Index)..<(swEndY as! C.Index)]
        
        let sw = construct(grid: grid, xStart: swStartX, xEnd: swEndX, yStart: swStartY, yEnd: swEndY)
        
        let seStartX = neStartX
        let seEndX = seStartX + xCount
        let seStartY = swStartY
        let seEndY = seStartY + yCount
//        let cellsSliceSE = grid[(seStartX as! C.Index)..<(seEndX as! C.Index)][(seStartY as! C.Index)..<(seEndY as! C.Index)]
        
        let se = construct(grid: grid, xStart: seStartX, xEnd: seEndX, yStart: seStartY, yEnd: seEndY)
        
        return join(nw: nw, ne: ne, sw: sw, se: se)
    }
    
    public static func expand(node: HLNode) -> [Bool] {
        if node.level == 0 {
            return [node.population == 1]
        }
        
        let top = [node.nw!, node.ne!].flatMap { expand(node: $0) }
        let bottom = [node.sw!, node.se!].flatMap { expand(node: $0) }
        
        return top + bottom
    }
    
    public func synchronizeState() {
        print("[synchronizeState] Population before update: \(root.population)")
        
        synchronizeState(node: root, xStart: 0, xCount: xCount, yStart: 0, yCount: yCount)
        
        print("[synchronizeState] Population after update: \(root.population)")
    }
    
    private func synchronizeState(node: HLNode, xStart: Int, xCount: Int, yStart: Int, yCount: Int) {
        // This assumption will break horribly if xCount or yCount are not the same power of 2:
        if node.level == 1 && xCount == 2 {
            node.nw!.population = grid[xStart][yStart].alive ? 1 : 0
            node.ne!.population = grid[xStart + 1][yStart].alive ? 1 : 0
            node.sw!.population = grid[xStart][yStart + 1].alive ? 1 : 0
            node.se!.population = grid[xStart + 1][yStart + 1].alive ? 1 : 0
        } else {
            let nCountX = Int(xCount / 2)
            let nCountY = Int(yCount / 2)
            
            let nwStartX = xStart
            let nwStartY = yStart
            synchronizeState(node: node.nw!, xStart: nwStartX, xCount: nCountX, yStart: nwStartY, yCount: nCountY)
            
            let neStartX = xStart + nCountX
            let neStartY = yStart
            synchronizeState(node: node.ne!, xStart: neStartX, xCount: nCountX, yStart: neStartY, yCount: nCountY)
            
            let swStartX = xStart
            let swStartY = yStart + nCountY
            synchronizeState(node: node.sw!, xStart: swStartX, xCount: nCountX, yStart: swStartY, yCount: nCountY)
            
            let seStartX = xStart + nCountX
            let seStartY = yStart + nCountY
            synchronizeState(node: node.se!, xStart: seStartX, xCount: nCountX, yStart: seStartY, yCount: nCountY)
        }
        
        node.synchronizePopulation()
    }
    
    // This should only apply to leaf (level 0) nodes in the quadtree:
    func applyLifeRules(for node: HLNode, neighbors: [HLNode]) -> HLNode {
        let liveNeighbors = neighbors.map((\.population)).reduce(0, +)
        let alive = liveNeighbors == 3 || (liveNeighbors == 2 && node.population == 1)
        return alive ? Self.alive : Self.dead
    }
    
    // This should only be called on level 2 nodes:
    func applyLifeRules4x4(node: HLNode) -> HLNode {
        let nw = applyLifeRules(for: node.nw!.se!, neighbors: [node.nw!.nw!,
                                                               node.nw!.ne!,
                                                               node.nw!.sw!,
                                                               node.ne!.nw!,
                                                               node.ne!.sw!,
                                                               node.sw!.nw!,
                                                               node.sw!.ne!,
                                                               node.se!.nw!])
        
        let ne = applyLifeRules(for: node.ne!.sw!, neighbors: [node.ne!.nw!,
                                                               node.ne!.ne!,
                                                               node.ne!.se!,
                                                               node.se!.nw!,
                                                               node.se!.ne!,
                                                               node.sw!.ne!,
                                                               node.nw!.ne!,
                                                               node.nw!.se!])
        
        let sw = applyLifeRules(for: node.sw!.ne!, neighbors: [node.sw!.nw!,
                                                               node.sw!.sw!,
                                                               node.sw!.se!,
                                                               node.se!.nw!,
                                                               node.se!.sw!,
                                                               node.ne!.sw!,
                                                               node.nw!.se!,
                                                               node.nw!.sw!])
        
        let se = applyLifeRules(for: node.se!.nw!, neighbors: [node.se!.ne!,
                                                               node.se!.se!,
                                                               node.se!.sw!,
                                                               node.ne!.sw!,
                                                               node.ne!.se!,
                                                               node.nw!.se!,
                                                               node.sw!.ne!,
                                                               node.sw!.se!])
        
        return Self.join(nw: nw, ne: ne, sw: sw, se: se)
    }
    
    static func join(nw: HLNode, ne: HLNode, sw: HLNode, se: HLNode) -> HLNode {
        let key = NodeKey(nw: ObjectIdentifier(nw),
                          ne: ObjectIdentifier(ne),
                          sw: ObjectIdentifier(sw),
                          se: ObjectIdentifier(se))
        
        if let existing = canonicalNodes[key.hashValue] {
            return existing
        }
        
        let node = HLNode(level: nw.level + 1, id: key.hashValue, nw: nw, ne: ne, sw: sw, se: se)
        canonicalNodes[key.hashValue] = node
        return node
    }
    
    public func nextGeneration(for node: HLNode) -> HLNode {
        // Empty node:
        if node.population == 0 {
            return node.nw!
        }
        
        if node.level == 2 {
            return applyLifeRules4x4(node: node)
        }
        
        // Sliding window Z pattern, left-to-right and top-to-bottom, with grandchildren of node:
        let window1 = nextGeneration(for: Self.join(nw: node.nw!.nw!, ne: node.nw!.ne!, sw: node.nw!.sw!, se: node.nw!.se!))
        let window2 = nextGeneration(for: Self.join(nw: node.nw!.ne!, ne: node.ne!.nw!, sw: node.nw!.se!, se: node.ne!.sw!))
        let window3 = nextGeneration(for: Self.join(nw: node.ne!.nw!, ne: node.ne!.ne!, sw: node.ne!.sw!, se: node.ne!.se!))
        let window4 = nextGeneration(for: Self.join(nw: node.nw!.sw!, ne: node.nw!.se!, sw: node.sw!.nw!, se: node.sw!.ne!))
        let window5 = nextGeneration(for: Self.join(nw: node.nw!.se!, ne: node.ne!.sw!, sw: node.sw!.ne!, se: node.se!.nw!))
        let window6 = nextGeneration(for: Self.join(nw: node.ne!.sw!, ne: node.ne!.se!, sw: node.se!.nw!, se: node.se!.ne!))
        let window7 = nextGeneration(for: Self.join(nw: node.sw!.nw!, ne: node.sw!.ne!, sw: node.sw!.sw!, se: node.sw!.se!))
        let window8 = nextGeneration(for: Self.join(nw: node.sw!.ne!, ne: node.se!.nw!, sw: node.sw!.se!, se: node.se!.sw!))
        let window9 = nextGeneration(for: Self.join(nw: node.se!.nw!, ne: node.se!.ne!, sw: node.se!.sw!, se: node.se!.se!))
        
        // Combine inner windows:
        let ngNW = Self.join(nw: window1.se!, ne: window2.sw!, sw: window4.ne!, se: window5.nw!)
        let ngNE = Self.join(nw: window2.se!, ne: window3.sw!, sw: window5.ne!, se: window6.nw!)
        let ngSW = Self.join(nw: window4.se!, ne: window5.sw!, sw: window7.ne!, se: window8.nw!)
        let ngSE = Self.join(nw: window5.se!, ne: window6.sw!, sw: window8.ne!, se: window9.nw!)
        
        return Self.join(nw: ngNW, ne: ngNE, sw: ngSW, se: ngSE)
    }
    
//    public func successor(for node: HLNode) -> HLNode {
//        if node.level == 2 {
//            return applyLifeRules4x4(node: node)
//        }
//        
//        // This is probably wrong:
//        let nw = successor(for: node.nw!)
//        let ne = successor(for: node.ne!)
//        let sw = successor(for: node.sw!)
//        let se = successor(for: node.se!)
//        
//        return join(nw: nw, ne: ne, sw: sw, se: se)
//    }
    
    public static func getZeroNode(at level: UInt64) -> HLNode {
        if level == 0 {
            return dead
        }
        
        return join(nw: getZeroNode(at: level - 1),
                    ne: getZeroNode(at: level - 1),
                    sw: getZeroNode(at: level - 1),
                    se: getZeroNode(at: level - 1))
    }
    
    public static func center(node: HLNode) -> HLNode {
        let zeroNode = getZeroNode(at: node.level - 1)
        
        let nw = join(nw: zeroNode, ne: zeroNode, sw: zeroNode, se: node.nw!)
        let ne = join(nw: zeroNode, ne: zeroNode, sw: node.ne!, se: zeroNode)
        let sw = join(nw: zeroNode, ne: node.sw!, sw: zeroNode, se: zeroNode)
        let se = join(nw: node.se!, ne: zeroNode, sw: zeroNode, se: zeroNode)
        
        return join(nw: nw, ne: ne, sw: sw, se: se)
    }
    
//    public func update(generation: UInt64) -> UInt64 {
//        updateQueue.sync {
//            // Compute next generation:
//            let nextGen = nextGeneration(for: self.root)
////            print("[Hashlife update] nextGen level: \(nextGen.level)")
//            let nextGenCentered = Self.center(node: nextGen)
//            let lifeBitmap = Self.expand(node: nextGenCentered)
//            self.root = nextGenCentered
//            
//            DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                for (x, cell) in self.grid[y].enumerated() {
//                    cell.nextState = lifeBitmap[y*xCount + x]
//                    cell.update()
//                }
//            }
//        }
//
//        return generation + 1
//    }
    
    private func updateCells(node: HLNode, xStart: Int, yStart: Int, size: Int) {
        if node.level == 0 {
            grid[yStart][xStart].nextState = node.population == 1
            grid[yStart][xStart].update()
        } else {
            let half = size / 2
            
            // TODO: Make these 4 calls concurrent ???
            updateCells(node: node.nw!, xStart: xStart,         yStart: yStart,        size: half)
            updateCells(node: node.ne!, xStart: xStart + half,  yStart: yStart,        size: half)
            updateCells(node: node.sw!, xStart: xStart,         yStart: yStart + half, size: half)
            updateCells(node: node.se!, xStart: xStart + half,  yStart: yStart + half, size: half)
        }
    }
    
    public func update(generation: UInt64) -> UInt64 {
        updateQueue.sync {
            // Compute next generation:
            let centeredRoot = Self.center(node: root)
            root = nextGeneration(for: centeredRoot)
            updateCells(node: root, xStart: 0, yStart: 0, size: xCount)
        }
        
        return generation + 1
    }
}
