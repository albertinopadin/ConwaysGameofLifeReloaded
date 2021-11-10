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
    let quarterCountX: Int
    let quarterCountY: Int
    var grid = ContiguousArray<ContiguousArray<Cell>>()   // 2D Array to hold the cells
    var tileMap = SKTileMapNode()
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    
    var shadowed = [Cell]()
    
    let tileSet = SKTileSet(named: "Sample Grid Tile Set")!
    let liveGroup: SKTileGroup
    let deadGroup: SKTileGroup
    
    var toggle: Bool = false
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        quarterCountX = xCount / 4
        quarterCountY = yCount / 4
        self.cellSize = cellSize
        
        // Set up tile map:
        let tileSize = CGSize(width: cellSize, height: cellSize)
        tileSet.defaultTileSize = tileSize
        liveGroup = tileSet.tileGroups.first(where: { $0.name == "Live" })!
        deadGroup = tileSet.tileGroups.first(where: { $0.name == "Dead" })!
        tileMap = SKTileMapNode(tileSet: tileSet, columns: xCount, rows: yCount, tileSize: tileSize)
        tileMap.enableAutomapping = true
        tileMap.fill(with: deadGroup)
        
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
        
        // Set up cell grid to back the tile map:
        grid = makeGrid(xCells: xCells, yCells: yCells)
        setNeighborsForAllCellsInGrid()
    }
    
    func makeGrid(xCells: Int, yCells: Int) -> ContiguousArray<ContiguousArray<Cell>> {
        let initialCell = Cell(column: 0, row: 0)
        let newGridRow = ContiguousArray<Cell>(repeating: initialCell, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<Cell>>(repeating: newGridRow, count: xCells)
        for x in 0..<xCells {
            for y in 0..<yCells {
                newGrid[x][y] = Cell(column: x, row: y)
            }
        }
        return newGrid
    }
    
    // Returns the middle coordinate given an iteration and a length
    // Example: If the cell is in iteration 0 and the length of a side
    // of the cell is 4, the cell middle would be 2.
    // Useful to position cells by their center point
    private func cellMiddle(iteration: Int, length: CGFloat) -> CGFloat {
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
        let upperLeftNeighbor   = leftX > -1 && topY < (grid.first?.count)! ? grid[leftX][topY] : nil
        let upperNeighbor       = topY < (grid.first?.count)! ? grid[x][topY] : nil
        let upperRightNeighbor  = rightX < grid.count && topY < (grid.first?.count)! ? grid[rightX][topY] : nil
        let rightNeighbor       = rightX < grid.count ? grid[rightX][y] : nil
        let lowerRightNeighbor  = rightX < grid.count && bottomY > -1 ? grid[rightX][bottomY] : nil
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
    
    @inlinable func makeTileLive(column: Int, row: Int) {
        tileMap.setTileGroup(liveGroup, forColumn: column, row: row)
    }
    
    @inlinable func makeTileDead(column: Int, row: Int) {
        tileMap.setTileGroup(deadGroup, forColumn: column, row: row)
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
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    @inlinable func update() -> UInt64 {
        // Prepare update:
        DispatchQueue.global(qos: .userInteractive).sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].prepareUpdate()
                }
            }
        }
        
//        for x in 0..<xCount {
//            for y in 0..<yCount {
//                self.grid[x][y].prepareUpdate()
//            }
//        }
        
//        DispatchQueue.global(qos: .userInteractive).sync {
//            DispatchQueue.concurrentPerform(iterations: quarterCountX) { x in
//                DispatchQueue.concurrentPerform(iterations: quarterCountY) { y in
//                    self.grid[x][y].prepareUpdate()
//                }
//            }
//        }

        // Update
        // Doing concurrentPerform on both inner and outer loops doubles FPS:
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    let cell = self.grid[x][y]
                    if cell.needsUpdate() {
                        cell.update()
                        if cell.alive() {
                            self.makeTileLive(column: x, row: y)
                        } else {
                            self.makeTileDead(column: x, row: y)
                        }
                    }
                }
            }
        }
        
//        for x in 0..<xCount {
//            for y in 0..<yCount {
//                if self.grid[x][y].needsUpdate() {
//                    print("Cell \(x), \(y) needs update.")
//                    self.grid[x][y].update()
//                    if self.grid[x][y].alive() {
//                        self.makeTileLive(column: x, row: y)
//                    } else {
//                        self.makeTileDead(column: x, row: y)
//                    }
//                }
//            }
//        }
        
//        DispatchQueue.global(qos: .userInteractive).sync {
//            DispatchQueue.concurrentPerform(iterations: quarterCountX) { x in
//                DispatchQueue.concurrentPerform(iterations: quarterCountY) { y in
//                    self.grid[x][y].update()
//                }
//            }
//        }
        
        // TODO: hitting weird bug where sometimes gliders will 'explode' or 'disintegrate'...
        
//        toggle.toggle()
//
//        if toggle {
////            tileMap.setTileGroup(liveGroup, forColumn: 200, row: 200)
//            makeTileLive(column: 200, row: 200)
//        } else {
////            tileMap.setTileGroup(deadGroup, forColumn: 200, row: 200)
//            makeTileDead(column: 200, row: 200)
//        }
        
        
        generation += 1
        return generation
    }

    func getGridIndicesFromPoint(at: CGPoint) -> (x: Int, y: Int) {
        let xIndex = Int(at.x / cellSize)
        let yIndex = Int(at.y / cellSize)
        
        return (xIndex, yIndex)
    }
        
    // TODO: Fix index out of bounds bug here:
    func touchedCell(at: CGPoint, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellSize)
        let y = Int(at.y / cellSize)

        let touchedCell = grid[x][y]
        if !withAltAction && !touchedCell.alive() {
            touchedCell.makeLive(touched: true)
            makeTileLive(column: x, row: y)
        }

        if withAltAction && touchedCell.alive() {
            touchedCell.makeDead(touched: true)
            makeTileDead(column: x, row: y)
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
            makeTileLive(column: x, row: y)
        }
    }
    
    func resetShadowed() {
        for cell in shadowed {
//            cell.color = .blue
        }
        shadowed.removeAll()
    }
    
    func shadowPattern(with points: [CGPoint]) {
        for p in points {
            let x = Int(p.x / cellSize)
            let y = Int(p.y / cellSize)

//            let cell = grid[x][y]
//            if !cell.alive() {
//                cell.makeShadow()
//                shadowed.append(cell)
//            }
        }
    }
    
//    func getPointDimensions() -> (CGFloat, CGFloat) {
//        return (getPointWidth(), getPointHeight())
//    }
//
//    func getPointWidth() -> CGFloat {
//        return CGFloat(grid.count) * cellSize
//    }
//
//    func getPointHeight() -> CGFloat {
//        guard let gridY = grid.first else {
//            return 0
//        }
//
//        return CGFloat(gridY.count) * cellSize
//    }
    
    func reset() {
        // Reset the game to initial state with no cells alive:
        DispatchQueue.global(qos: .userInteractive).sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeDead()
                    makeTileDead(column: x, row: y)
                }
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
    
    // TODO: Would be fun to randomize cell states as a starting condition,
    //       and see what happens.
    func randomState(liveProbability: Double) {
        reset()
        if liveProbability == 1.0 {
            makeAllLive()
        } else {
            if liveProbability > 0.0 {
                let liveProb = Int(liveProbability*100)
                DispatchQueue.global(qos: .userInteractive).sync {
                    DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                        DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                            let randInt = Int.random(in: 0...100)
                            if randInt <= liveProb {
                                self.grid[x][y].makeLive()
                                makeTileLive(column: x, row: y)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func makeAllLive() {
        DispatchQueue.global(qos: .userInteractive).sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeLive()
                    makeTileLive(column: x, row: y)
                }
            }
        }
    }
    
}
