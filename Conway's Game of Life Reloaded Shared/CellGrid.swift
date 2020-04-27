//
//  CellGrid.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/15/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit

enum Orientation {
    case Horizontal
    case Vertical
}

class CellGrid {
    var grid = [[Cell]]()    // 2D Array to hold the cells
    var cellWidth: CGFloat = 23.0
    var cellHeight: CGFloat = 23.0
    var generation: UInt64 = 0
    
    
    init(xDimension: Int, yDimension: Int) {
        grid = makeVisibleGrid(xDimension: xDimension, yDimension: yDimension)
    }
    
    init(xDimension: Int, yDimension: Int, xCells: Int, yCells: Int, zoomLevel: CGFloat) {
        grid = makeGrid(xCells: xCells,
                        yCells: yCells,
                        xDimension: xDimension,
                        yDimension: yDimension,
                        zoomLevel: zoomLevel)
    }
    
    func makeGrid(xCells: Int, yCells: Int, xDimension: Int, yDimension: Int, zoomLevel: CGFloat) -> [[Cell]] {
        var newGrid = makeVisibleGrid(xDimension: xDimension, yDimension: yDimension)
        let visibleCellsX = newGrid.count
        let visibleCellsY = newGrid[0].count

        if xCells > visibleCellsX {
            let overflowCells = xCells - visibleCellsX
            let leftOverflow = Int(overflowCells/2)
            let rightOverflow = overflowCells - leftOverflow
            
            // Insert cells to the left:
            for x in 0..<leftOverflow {
                var cellsLeft = [Cell]()
                for y in 0..<visibleCellsY {
                    let xIter = -x - 1
                    let cellFrame = CGRect(x: cellMiddle(iteration: xIter, length: cellWidth),
                                           y: cellMiddle(iteration: y, length: cellHeight),
                                           width: cellWidth,
                                           height: cellHeight)
                    cellsLeft.append(Cell(frame: cellFrame))
                }
                newGrid.append(cellsLeft)
            }
            
            // Insert cells to the right:
            for x in 0..<rightOverflow {
                var cellsRight = [Cell]()
                for y in 0..<visibleCellsY {
                    let xIter = visibleCellsX + x
                    let cellFrame = CGRect(x: cellMiddle(iteration: xIter, length: cellWidth),
                                           y: cellMiddle(iteration: y, length: cellHeight),
                                           width: cellWidth,
                                           height: cellHeight)
                    cellsRight.append(Cell(frame: cellFrame))
                }
                newGrid.append(cellsRight)
            }
        }
        
        
        if yCells > visibleCellsY {
            let totalCellsX = newGrid.count
            let overflowCells = yCells - visibleCellsY
            let topOverflow = Int(overflowCells/2)
            let bottomOverflow = overflowCells - topOverflow
            
            // Insert cells at top:
            for y in 0..<topOverflow {
                var cellsTop = [Cell]()
                for x in 0..<totalCellsX {
                    let xIter = -Int((xCells - visibleCellsX)/2) + x
                    let yIter = -y - 1
                    let cellFrame = CGRect(x: cellMiddle(iteration: xIter, length: cellWidth),
                                           y: cellMiddle(iteration: yIter, length: cellHeight),
                                           width: cellWidth,
                                           height: cellHeight)
                    cellsTop.append(Cell(frame: cellFrame))
                }
                newGrid.append(cellsTop)
            }
            
            // Insert cells at bottom:
            for y in 0..<bottomOverflow {
                var cellsBottom = [Cell]()
                for x in 0..<totalCellsX {
                    let xIter = -Int((xCells - visibleCellsX)/2) + x
                    let yIter = visibleCellsY + y
                    let cellFrame = CGRect(x: cellMiddle(iteration: xIter, length: cellWidth),
                                           y: cellMiddle(iteration: yIter, length: cellHeight),
                                           width: cellWidth,
                                           height: cellHeight)
                    cellsBottom.append(Cell(frame: cellFrame))
                }
                newGrid.append(cellsBottom)
            }
        }
        
        return newGrid
    }
    
    func makeVisibleGrid(xDimension: Int, yDimension: Int) -> [[Cell]] {
        var newGrid = [[Cell]]()
        for x in 0...xDimension {
            newGrid.append([Cell]())    // Create new Cell array for this xz
            for y in 0...yDimension {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellWidth),
                                       y: cellMiddle(iteration: y, length: cellHeight),
                                       width: cellWidth,
                                       height: cellHeight)
                newGrid[x].append(Cell(frame: cellFrame))
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
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    func updateCells() -> UInt64 {
        // First do a deep copy of cell grid:
        let prevGenGrid = self.deepCopyCellArray(originalGrid: self.grid)
        
        // Iterate through the current grid, updating the next gen grid accordingly:
        for x in 0..<self.grid.count {
            for y in 0..<self.grid.first!.count {
                let numberOfLiveNeighbors = self.getNumberOfLiveNeighbors(x: x, y: y, grid: prevGenGrid)
                let currentGenCell = self.grid[x][y]
                let prevGenCell = prevGenGrid[x][y]
                
                switch numberOfLiveNeighbors {
                case _ where numberOfLiveNeighbors < 2:
                    if prevGenCell.alive {
                        // Cell dies
                        currentGenCell.makeDead()
                    }
                    
                case 2:
                    break
                    
                case 3:
                    if !prevGenCell.alive {
                        currentGenCell.makeLive()
                    }
                    
                case _ where numberOfLiveNeighbors > 3:
                    if prevGenCell.alive {
                        currentGenCell.makeDead()
                    }
                    
                default:
                    break
                }
            }
        }
        
        generation += 1
        return generation
    }
    
    func deepCopyCellArray(originalGrid: [[Cell]]) -> [[Cell]] {
        var copyGrid = [[Cell]]()
        // Need to find a fast way to deep copy array of objects;
        // For now will use for loop:
        for cellArray in originalGrid {
            copyGrid.append([Cell]())
            let cellRowIndex = copyGrid.count - 1
            
            // Deep copy of cell objects:
            for originalCell in cellArray {
                copyGrid[cellRowIndex].append(Cell(frame: originalCell.frame,
                                                   alive: originalCell.alive,
                                                   color: originalCell.color))
            }
        }
        
        return copyGrid
    }
        
    func getNumberOfLiveNeighbors(x: Int, y: Int, grid: [[Cell]]) -> Int {
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
        
        var numLiveNeighbors = 0
        // ... There's got to be a better way...
        if let lf_n = leftNeighbor { if lf_n.alive { numLiveNeighbors += 1 } }
        if let ul_n = upperLeftNeighbor { if ul_n.alive { numLiveNeighbors += 1 } }
        if let u_n = upperNeighbor { if u_n.alive { numLiveNeighbors += 1 } }
        if let ur_n = upperRightNeighbor { if ur_n.alive { numLiveNeighbors += 1 } }
        if let r_n = rightNeighbor { if r_n.alive { numLiveNeighbors += 1 } }
        if let lwr_n = lowerRightNeighbor { if lwr_n.alive { numLiveNeighbors += 1 } }
        if let lw_n = lowerNeighbor { if lw_n.alive { numLiveNeighbors += 1 } }
        if let lwl_n = lowerLeftNeighbor { if lwl_n.alive { numLiveNeighbors += 1 } }
        
        return numLiveNeighbors
    }

    func getGridIndicesFromPoint(at: CGPoint) -> (x: Int, y: Int) {
        let xIndex = Int(at.x / cellWidth)
        let yIndex = Int(at.y / cellHeight)
        
        return (xIndex, yIndex)
    }
        
    // TODO: Fix index out of bounds bug here:
    func spawnLiveCell(at: CGPoint) {
        // Find the cell that contains the touch point and make it live:
        //        let (x, y) = self.getGridIndicesFromPoint(at: at)
        
        let x = Int(at.x / cellWidth)
        let y = Int(at.y / cellHeight)
        
        let touchedCell = self.grid[x][y]
        if !touchedCell.alive {
            touchedCell.makeLive()
        }
        
        // TODO: Implement this the O(1) way
        // For now will just be a loop:
        //        for x in 0...xDimension {
        //            for y in 0...yDimension {
        //                let nthCell = self.grid[x][y]
        //                if nthCell.frame.contains(at) {
        //                    if !nthCell.alive {
        //                        nthCell.makeLive()
        //                    }
        //
        //                    print("Indices of touch: \(x, y)")
        //
        //                    // Break out of loop as we already found cell that contains the point:
        //                    break
        //                }
        //            }
        //        }
    }
    
    func reset() {
        // Reset the game to initial state with no cells alive:
        if !self.grid.isEmpty {
            for cellArray in self.grid {
                for cell in cellArray {
                    cell.makeDead()
                }
            }
        }
        
        generation = 0
    }
}
