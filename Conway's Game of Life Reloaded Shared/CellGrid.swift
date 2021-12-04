//
//  CellGrid.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit


final class CellGrid {
    let xCount: Int
    let yCount: Int
    let halfCountX: Int
    let halfCountY: Int
    final var cellBuffer0 = [[UInt8]]()   // 2D Array to hold the cells
    final var cellBuffer1 = [[UInt8]]()   // 2D Array to hold the cells
    final var spriteGrid  = ContiguousArray<ContiguousArray<SKSpriteNode>>()   // 2D Array to hold the cells
//    final var cellBuffer = [[UInt8]]()
//    final var cellBufferNext = [[UInt8]]()
    final var cellBuffer0InUse: Bool = true
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    var shadowed = [Cell]()
    final let updateQueue = DispatchQueue(label: "cgol.update.queue",
                                          qos: .userInteractive,
                                          attributes: .concurrent)
    
    final let aliveColor: SKColor = .green
    final let deadColor = SKColor(red: 0.16, green: 0.15, blue: 0.30, alpha: 1.0)
    final let shadowColor: SKColor = .darkGray
    final let colorNodeSizeFraction: CGFloat = 0.92
    
    final let colorAliveAction = SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.3)
    final let colorDeadAction = SKAction.colorize(with: SKColor(red: 0.16,
                                                                 green: 0.15,
                                                                 blue: 0.30,
                                                                 alpha: 1.0),
                                                    colorBlendFactor: 1.0,
                                                    duration: 0.3)
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        halfCountX = Int(xCells/2)
        halfCountY = Int(yCells/2)
        self.cellSize = cellSize
        cellBuffer0 = makeCellBuffer(xCells: xCells, yCells: yCells)
        cellBuffer1 = makeCellBuffer(xCells: xCells, yCells: yCells)
        spriteGrid = makeSpriteGrid(xCells: xCells, yCells: yCells)
        // Maybe do this as arrays of pointers into the neighbors???
//        setNeighborsForAllCellsInBuffer(buffer: cellBuffer0)
//        setNeighborsForAllCellsInBuffer(buffer: cellBuffer1)
//        cellBuffer = cellBuffer0
//        cellBufferNext = cellBuffer0
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
    }
    
    @inlinable
    @inline(__always)
    final func makeCellBuffer(xCells: Int, yCells: Int) -> [[UInt8]] {
//        let newBufferRow = ContiguousArray<Bool>(repeating: false, count: yCells)
//        return ContiguousArray<ContiguousArray<Bool>>(repeating: newBufferRow, count: xCells)
        
        let newBufferRow = [UInt8](repeating: 0, count: yCells)
        var newBuffer = [[UInt8]](repeating: newBufferRow, count: xCells)
        for x in 0..<xCells {
            for y in 0..<yCells {
                newBuffer[x][y] = 0
            }
        }
        
        return newBuffer
    }
    
    @inlinable
    @inline(__always)
    final func makeSpriteGrid(xCells: Int, yCells: Int) -> ContiguousArray<ContiguousArray<SKSpriteNode>> {
        let initialSprite = SKSpriteNode(texture: nil,
                                   color: aliveColor,
                                   size: CGSize.zero)
        let newGridRow = ContiguousArray<SKSpriteNode>(repeating: initialSprite, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<SKSpriteNode>>(repeating: newGridRow, count: xCells)

        for x in 0..<xCells {
            for y in 0..<yCells {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!

                // For adding directly to scene:
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize),
                                       y: cellMiddle(iteration: y, length: cellSize),
                                       width: cellSize,
                                       height: cellSize)
                
                let node = SKSpriteNode(texture: nil,
                                        color: aliveColor,
                                        size: CGSize(width: cellFrame.size.width * colorNodeSizeFraction,
                                                     height: cellFrame.size.height * colorNodeSizeFraction))
                node.position = cellFrame.origin
                node.blendMode = .replace
                node.physicsBody?.isDynamic = false

                node.texture?.filteringMode = .nearest
                node.centerRect = CGRect(x: 0.5, y: 0.5, width: 0.0, height: 0.0)
                node.alpha = CellAlpha.dead
                
                newGrid[x][y] = node
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
    
//    private func setNeighborsForAllCellsInBuffer(buffer: ContiguousArray<ContiguousArray<Cell>>) {
//        for x in 0..<xCount {
//            for y in 0..<yCount {
//                buffer[x][y].neighbors = getCellNeighbors(x: x, y: y, buffer: buffer)
//            }
//        }
//    }
    
    @inlinable
    @inline(__always)
    public func getLiveNeighbors(x: Int, y: Int, buffer: [[UInt8]]) -> UInt8 {
        var liveNeighbors: UInt8 = 0
        
        // Get the neighbors:
        let leftX   = x - 1
        let rightX  = x + 1
        let topY    = y + 1
        let bottomY = y - 1
        
        let leftNeighbor        = leftX > -1 ? buffer[leftX][y] : nil
        let upperLeftNeighbor   = leftX > -1 && topY < yCount ? buffer[leftX][topY] : nil
        let upperNeighbor       = topY < yCount ? buffer[x][topY] : nil
        let upperRightNeighbor  = rightX < xCount && topY < yCount ? buffer[rightX][topY] : nil
        let rightNeighbor       = rightX < xCount ? buffer[rightX][y] : nil
        let lowerRightNeighbor  = rightX < xCount && bottomY > -1 ? buffer[rightX][bottomY] : nil
        let lowerNeighbor       = bottomY > -1 ? buffer[x][bottomY] : nil
        let lowerLeftNeighbor   = leftX > -1 && bottomY > -1 ? buffer[leftX][bottomY] : nil
        
        if let left_n = leftNeighbor {
            liveNeighbors += left_n
        }
        
        if let upper_left_n = upperLeftNeighbor {
            liveNeighbors += upper_left_n
        }
        
        if let upper_n = upperNeighbor {
            liveNeighbors += upper_n
        }
        
        if let upper_right_n = upperRightNeighbor {
            liveNeighbors += upper_right_n
        }
        
        if let right_n = rightNeighbor {
            liveNeighbors += right_n
        }
        
        if let lower_right_n = lowerRightNeighbor {
            liveNeighbors += lower_right_n
        }
        
        if let lower_n = lowerNeighbor {
            liveNeighbors += lower_n
        }
        
        if let lower_left_n = lowerLeftNeighbor {
            liveNeighbors += lower_left_n
        }
        
        return liveNeighbors
    }
    
//    @inlinable func prepareUpdateCells() {
//        // Prepare update:
//        DispatchQueue.global(qos: .userInteractive).sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                    self.grid[x][y].prepareUpdate()
//                }
//            }
//        }
//    }
    
//    @inlinable
//    @inline(__always)
//    final func switchCellBuffer() {
//        if cellBuffer0InUse {
//            cellBuffer = cellBuffer1
//            cellBufferNext = cellBuffer0
//        } else {
//            cellBuffer = cellBuffer0
//            cellBufferNext = cellBuffer1
//        }
//        cellBuffer0InUse.toggle()
//    }
    
    @inlinable
    @inline(__always)
    final func getCellState(currentState: UInt8, liveNeighbors: UInt8) -> UInt8 {
        if !(currentState == 0 && liveNeighbors < 3) {
            return (currentState == 1 && liveNeighbors == 2) || (liveNeighbors == 3) ? 1: 0
        } else {
            return currentState
        }
    }
    
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    @inlinable
    @inline(__always)
    final func updateCells() -> UInt64 {
//        let numLive = cellBuffer.lazy.joined().filter({ $0 == 1 }).count
//        print("Gen: \(generation)")
//        print("Number of live: \(numLive)")
        
        //  FPS on 200x200
        //  FPS on 400x400
        //  FPS on 800x800
        // Prepare update & Update all in one go:
        // Doing concurrentPerform on both inner and outer loops doubles FPS:
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                    let liveNeighbors = self.getLiveNeighbors(x: x, y: y, buffer: self.cellBuffer)
//                    let live = self.getCellState(currentState: self.cellBuffer[x][y],
//                                                 liveNeighbors: liveNeighbors)
//
//                    self.cellBufferNext[x][y] = live
//                    if live == 1 {
//                        self.spriteGrid[x][y].alpha = CellAlpha.live
//                    } else {
//                        self.spriteGrid[x][y].alpha = CellAlpha.dead
//                    }
//                }
//            }
//
//            self.switchCellBuffer()
//        }
        
        
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    if self.cellBuffer0InUse {
                        let liveNeighbors = self.getLiveNeighbors(x: x, y: y, buffer: self.cellBuffer0)
                        let live = self.getCellState(currentState: self.cellBuffer0[x][y],
                                                     liveNeighbors: liveNeighbors)
                        
                        self.cellBuffer1[x][y] = live
                        if live == 1 {
                            self.spriteGrid[x][y].alpha = CellAlpha.live
                        } else {
                            self.spriteGrid[x][y].alpha = CellAlpha.dead
                        }
                    } else {
                        let liveNeighbors = self.getLiveNeighbors(x: x, y: y, buffer: self.cellBuffer1)
                        let live = self.getCellState(currentState: self.cellBuffer1[x][y],
                                                     liveNeighbors: liveNeighbors)
                        
                        self.cellBuffer0[x][y] = live
                        if live == 1 {
                            self.spriteGrid[x][y].alpha = CellAlpha.live
                        } else {
                            self.spriteGrid[x][y].alpha = CellAlpha.dead
                        }
                    }
                }
            }

            self.cellBuffer0InUse.toggle()
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
    @inline(__always)
    final func touchedCell(at: CGPoint, gameRunning: Bool, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellSize)
        let y = Int(at.y / cellSize)

        let touchedCell = cellBuffer0InUse ? cellBuffer0[x][y]: cellBuffer1[x][y]
        if !withAltAction && touchedCell == 0 {
//            updateQueue.sync(flags: .barrier) {
//                spriteGrid[x][y].alpha = CellAlpha.live
//                cellBuffer[x][y] = true
//            }
            spriteGrid[x][y].alpha = CellAlpha.live
            if cellBuffer0InUse {
                cellBuffer0[x][y] = 1
            } else {
                cellBuffer1[x][y] = 1
            }
        }
        
        if withAltAction && touchedCell == 1 {
//            updateQueue.sync(flags: .barrier) {
//                spriteGrid[x][y].alpha = CellAlpha.dead
//                cellBuffer[x][y] = false
//            }
            spriteGrid[x][y].alpha = CellAlpha.dead
            if cellBuffer0InUse {
                cellBuffer0[x][y] = 0
            } else {
                cellBuffer1[x][y] = 0
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

            if cellBuffer0InUse {
                cellBuffer0[x][y] = 1
            } else {
                cellBuffer1[x][y] = 1
            }
            spriteGrid[x][y].alpha = CellAlpha.live
        }
    }
    
//    func resetShadowed() {
//        for cell in shadowed {
//            cell.node.color = .blue
//        }
//        shadowed.removeAll()
//    }
    
    func resetShadowed() {
        print("Unimplemented")
    }
    
//    func shadowPattern(with points: [CGPoint]) {
//        for p in points {
//            let x = Int(p.x / cellSize)
//            let y = Int(p.y / cellSize)
//
//            let cell = grid[x][y]
//            if !cell.alive {
//                cell.makeShadow()
//                shadowed.append(cell)
//            }
//        }
//    }
    
    func shadowPattern(with points: [CGPoint]) {
        print("Unimplemented")
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
    @inline(__always)
    final func reset() {
        // Reset the game to initial state with no cells alive:
//        updateQueue.sync(flags: .barrier) {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                    self.cellBuffer[x][y] = 0
//                    spriteGrid[x][y].alpha = CellAlpha.dead
//                }
//            }
//        }
        
        for x in 0..<xCount {
            for y in 0..<yCount {
                self.cellBuffer0[x][y] = 0
                self.cellBuffer1[x][y] = 0
                spriteGrid[x][y].alpha = CellAlpha.dead
            }
        }
        
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
    @inline(__always)
    final func randomState(liveProbability: Double) {
        reset()
        if liveProbability == 1.0 {
            makeAllLive()
        } else {
            if liveProbability > 0.0 {
                let liveProb = Int(liveProbability*100)
//                updateQueue.sync {
//                    DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                        DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                            let randInt = Int.random(in: 0...100)
//                            if randInt <= liveProb {
//                                self.cellBuffer[x][y] = 1
//                                spriteGrid[x][y].alpha = CellAlpha.live
//                            }
//                        }
//                    }
//                }
                
                for x in 0..<xCount {
                    for y in 0..<yCount {
                        let randInt = Int.random(in: 0...100)
                        if randInt <= liveProb {
                            self.cellBuffer0[x][y] = 1
                            spriteGrid[x][y].alpha = CellAlpha.live
                        }
                    }
                }
                
                
                if cellBuffer0InUse {
                    let live = cellBuffer0.lazy.joined().filter({ $0 == 1 }).count
                    print("Number of live after setting random state: \(live)")
                } else {
                    let live = cellBuffer1.lazy.joined().filter({ $0 == 1 }).count
                    print("Number of live after setting random state: \(live)")
                }
                
//                grid.lazy.joined().forEach { cell in
//                    let randInt = Int.random(in: 0...100)
//                    if randInt <= liveProb {
//                        cell.makeLive()
//                    }
//                }
            }
        }
    }
    
    final func makeAllLive() {
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.cellBuffer0[x][y] = 1
                    spriteGrid[x][y].alpha = CellAlpha.live
                }
            }
        }
    }
    
}
