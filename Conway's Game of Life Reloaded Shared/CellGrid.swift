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
    let divCountX: Int
    let divCountY: Int
    let divFactor = 8
    final var grid = ContiguousArray<ContiguousArray<Cell>>()   // 2D Array to hold the cells
    var cellSize: CGFloat = 23.0
    var generation: UInt64 = 0
    var spaceshipFactory: SpaceshipFactory?
    var shadowed = [Cell]()
    final let updateQueue = DispatchQueue(label: "cgol.update.queue",
                                          qos: .userInteractive,
                                          attributes: .concurrent)
    
//    final let updateQueue = DispatchQueue(label: "cgol.update.queue", qos: .userInteractive)
    
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
//    final private var liveProbability: Double = 0.05
//    final private var randomBoolBuffer = ContiguousArray<ContiguousArray<Bool>>()
    final var joinedGrid = ContiguousArray<Cell>()
    final var totalCount: Int = 0
    
    init(xCells: Int, yCells: Int, cellSize: CGFloat) {
        xCount = xCells
        yCount = yCells
        divCountX = xCount / divFactor
        divCountY = yCount / divFactor
        self.cellSize = cellSize
        grid = makeGrid(xCells: xCells, yCells: yCells)
        setNeighborsForAllCellsInGrid()
        spaceshipFactory = SpaceshipFactory(cellSize: cellSize)
//        randomizeBoolBuffer(x: xCells, y: yCells)
        joinedGrid = ContiguousArray<Cell>(grid.joined())
        totalCount = xCells * yCells
    }
    
//    func setLiveProbability(_ probability: Double) {
//        liveProbability = probability
//    }
//
//    @inlinable
//    @inline(__always)
//    final func randomizeBoolBuffer(x xc: Int, y yc: Int) {
//        let colBoolBuf = ContiguousArray<Bool>(repeating: false, count: yc)
//        randomBoolBuffer = ContiguousArray<ContiguousArray<Bool>>(repeating: colBoolBuf, count: xc)
//        let liveProb = Int(liveProbability*100)
//        updateQueue.async {
//            DispatchQueue.concurrentPerform(iterations: xc) { x in
//                DispatchQueue.concurrentPerform(iterations: yc) { y in
//                    let randInt = Int.random(in: 0...100)
//                    if randInt <= liveProb {
//                        self.randomBoolBuffer[x][y] = true
//                    }
//                }
//            }
//        }
//    }
    
    @inlinable
    @inline(__always)
    final func makeGrid(xCells: Int, yCells: Int) -> ContiguousArray<ContiguousArray<Cell>> {
        let initialCell = Cell(frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                               liveColor: aliveColor,
                               deadColor: deadColor,
                               shadowColor: shadowColor,
                               colorAliveAction: colorAliveAction,
                               colorDeadAction: colorDeadAction)
        let newGridRow = ContiguousArray<Cell>(repeating: initialCell, count: yCells)
        var newGrid = ContiguousArray<ContiguousArray<Cell>>(repeating: newGridRow, count: xCells)

        // For adding to backing node:
//        let totalSize = CGSize(width: CGFloat(xCells)*cellSize, height: CGFloat(yCells)*cellSize)
//        let xOffset = totalSize.width/2
//        let yOffset = totalSize.height/2

        for x in 0..<xCells {
            for y in 0..<yCells {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!

                // For adding directly to scene:
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize),
                                       y: cellMiddle(iteration: y, length: cellSize),
                                       width: cellSize,
                                       height: cellSize)

                // For adding to backing node:
//                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellSize) - xOffset,
//                                       y: cellMiddle(iteration: y, length: cellSize) - yOffset,
//                                       width: cellSize,
//                                       height: cellSize)

                newGrid[x][y] = Cell(frame: cellFrame,
                                     liveColor: aliveColor,
                                     deadColor: deadColor,
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
    @inlinable
    @inline(__always)
    final func updateCells() -> UInt64 {
//        grid.withUnsafeMutableBufferPointer { buffer in
//            updateQueue.sync(flags: .barrier) {
//                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                        buffer.baseAddress![x][y].prepareUpdate()
//                    }
//                }
//            }
//
//            // Update
//            // Doing concurrentPerform on both inner and outer loops doubles FPS:
//            updateQueue.sync(flags: .barrier) {
//                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
//                        buffer.baseAddress![x][y].update()
//                    }
//                }
//            }
//        }
        
        
        // 20-43 FPS on 200x200 grid:
        // 9-26 FPS on 400x400 grid:
        // Prepare update:
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].prepareUpdate()
                }
            }
        }

        // Update
        // Doing concurrentPerform on both inner and outer loops doubles FPS:
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].update()
                }
            }
        }
        
        // 25-40+ FPS on 200x200 grid:
        // 10-20 FPS on 400x400 grid:
//        grid.lazy.joined().forEach({ $0.prepareUpdate() })
//        grid.lazy.joined().filter({ $0.needsUpdate() }).forEach({ $0.update() })
        
        
        
        
        // This also seems to have a similar FPS and Frametime as double concurrentPerform:
        // Prepare update:
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                self.grid[x].forEach { $0.prepareUpdate() }
//            }
//        }
//
//        // Update
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
//                self.grid[x].forEach { $0.update() }
//            }
//        }

        
        
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.totalCount) { i in
//                self.joinedGrid[i].prepareUpdate()
//            }
//        }
//
//        updateQueue.sync {
//            DispatchQueue.concurrentPerform(iterations: self.totalCount) { i in
//                self.joinedGrid[i].update()
//            }
//        }
        
//        grid.joined().forEach({ $0.prepareUpdate() })
//        grid.joined().filter({ $0.needsUpdate() }).forEach({ $0.update() })
        
//        updateQueue.sync(flags: .barrier) {
//            DispatchQueue.concurrentPerform(iterations: self.divCountX) { x in
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x][y].prepareUpdate()
//                    self.grid[x + self.divCountX][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY].prepareUpdate()
//                    self.grid[x + self.divCountX][y + self.divCountY].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*2][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*2].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*3][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY*3].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*3].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*2][y + self.divCountY].prepareUpdate()
//                    self.grid[x + self.divCountX][y + self.divCountY*3].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*3].prepareUpdate()
//                }
//
//                // 8
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*4][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY*4].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*4].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*5][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY*5].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*5].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*6][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY*6].prepareUpdate()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*6].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*7][y].prepareUpdate()
//                    self.grid[x][y + self.divCountY*7].prepareUpdate()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*7].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX][y + self.divCountY*4].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY].prepareUpdate()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*4].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*4].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*3].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX][y + self.divCountY*5].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY].prepareUpdate()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*5].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*5].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*3].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*5].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*4].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*2][y + self.divCountY*6].prepareUpdate()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*6].prepareUpdate()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*3].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*6].prepareUpdate()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*4].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*6].prepareUpdate()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*5].prepareUpdate()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*2][y + self.divCountY*7].prepareUpdate()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*2].prepareUpdate()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*7].prepareUpdate()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*3].prepareUpdate()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*7].prepareUpdate()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*4].prepareUpdate()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*7].prepareUpdate()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*5].prepareUpdate()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*7].prepareUpdate()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*6].prepareUpdate()
//                }
//            }
//        }

        
//        updateQueue.sync(flags: .barrier) {
//            DispatchQueue.concurrentPerform(iterations: self.divCountX) { x in
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x][y].update()
//                    self.grid[x + self.divCountX][y].update()
//                    self.grid[x][y + self.divCountY].update()
//                    self.grid[x + self.divCountX][y + self.divCountY].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*2][y].update()
//                    self.grid[x][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*2].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*3][y].update()
//                    self.grid[x][y + self.divCountY*3].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*3].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*2][y + self.divCountY].update()
//                    self.grid[x + self.divCountX][y + self.divCountY*3].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*3].update()
//                }
//
//                // 8
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*4][y].update()
//                    self.grid[x][y + self.divCountY*4].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*4].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*5][y].update()
//                    self.grid[x][y + self.divCountY*5].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*5].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*6][y].update()
//                    self.grid[x][y + self.divCountY*6].update()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*6].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*7][y].update()
//                    self.grid[x][y + self.divCountY*7].update()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*7].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX][y + self.divCountY*4].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY].update()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*4].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*4].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*3].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX][y + self.divCountY*5].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY].update()
//                    self.grid[x + self.divCountX*2][y + self.divCountY*5].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*5].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*3].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*5].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*4].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*2][y + self.divCountY*6].update()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*6].update()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*3].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*6].update()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*4].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*6].update()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*5].update()
//                }
//
//                DispatchQueue.concurrentPerform(iterations: self.divCountY) { y in
//                    self.grid[x + self.divCountX*2][y + self.divCountY*7].update()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*2].update()
//                    self.grid[x + self.divCountX*3][y + self.divCountY*7].update()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*3].update()
//                    self.grid[x + self.divCountX*4][y + self.divCountY*7].update()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*4].update()
//                    self.grid[x + self.divCountX*5][y + self.divCountY*7].update()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*5].update()
//                    self.grid[x + self.divCountX*6][y + self.divCountY*7].update()
//                    self.grid[x + self.divCountX*7][y + self.divCountY*6].update()
//                }
//            }
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
    @inlinable
    @inline(__always)
    final func touchedCell(at: CGPoint, gameRunning: Bool, withAltAction: Bool = false) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellSize)
        let y = Int(at.y / cellSize)

        let touchedCell = grid[x][y]
        if !withAltAction && !touchedCell.alive() {
            updateQueue.sync(flags: .barrier) {
                if gameRunning {
                    touchedCell.makeLive()
                } else {
                    touchedCell.makeLiveTouched()
                }
            }
        }
        
        if withAltAction && touchedCell.alive() {
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
            if !cell.alive() {
                cell.makeShadow()
                shadowed.append(cell)
            }
        }
    }
    
    func getPointDimensions() -> (CGFloat, CGFloat) {
        return (getPointWidth(), getPointHeight())
    }
    
    func getPointWidth() -> CGFloat {
        return CGFloat(grid.count) * cellSize
    }
    
    func getPointHeight() -> CGFloat {
        guard let gridY = grid.first else {
            return 0
        }
        
        return CGFloat(gridY.count) * cellSize
    }
    
    @inlinable
    @inline(__always)
    final func reset() {
        // Reset the game to initial state with no cells alive:
        updateQueue.sync(flags: .barrier) {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                    self.grid[x][y].makeDead()
                }
            }
        }
        
//        grid.lazy.joined().forEach({ $0.makeDead() })
        
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
                updateQueue.sync {
                    DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                        DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
                            let randInt = Int.random(in: 0...100)
                            if randInt <= liveProb {
                                self.grid[x][y].makeLive()
                            }
                        }
                    }
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
                    self.grid[x][y].makeLive()
                }
            }
        }
    }
    
}
