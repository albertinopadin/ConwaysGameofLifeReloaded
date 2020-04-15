//
//  GameScene.swift
//  Conway's Game of Life Reloaded Shared
//
//  Created by Albertino Padin on 4/14/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var grid = [[Cell]]()    // 2D Array to hold the cells
    var cellWidth: CGFloat = 23.0
    var cellHeight: CGFloat = 23.0
    
    var updateInterval: Double = 0.25
    var previousTime: TimeInterval!

    // Need to initialize on sceneDidLoad!!!
    var xDimension: Int = 0
    var yDimension: Int = 0
    
    var dScale: Int = 23
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Failed to load GameScene.sks")
            abort()
        }

        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill

        return scene
    }
    
    func setUpScene() {
        (self.xDimension, self.yDimension) = self.initDimensionsBasedOnDeviceViewport();
        
        self.grid = self.makeGrid(xDimension: xDimension, yDimension: yDimension)
        self.addCellGridToScene(cellGrid: self.grid)
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
    }
    
    func initDimensionsBasedOnDeviceViewport() -> (Int, Int) {
        let xDim = Int(self.frame.size.width / CGFloat(dScale))
        let yDim = Int(self.frame.size.height / CGFloat(dScale))
        return (xDim, yDim)
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif
    
    func addCellGridToScene(cellGrid: [[Cell]]) {
        for cellArray in cellGrid {
            for cell in cellArray {
                self.addChild(cell)
            }
        }
    }
    
    func testAddCells() {
        let midCell = Cell(frame: CGRect(x: self.frame.midX,
                                         y: self.frame.midY,
                                         width: cellWidth,
                                         height: cellHeight),
                           alive: true,
                           color: .red)
        
        self.addChild(midCell)
        
        let originCell = Cell(frame: CGRect(x: 0,
                                            y: 0,
                                            width: cellWidth,
                                            height: cellHeight),
                              alive: true,
                              color: .green)
        
        self.addChild(originCell)
        
        let maxCell = Cell(frame: CGRect(x: self.frame.maxX,
                                         y: self.frame.maxY,
                                         width: cellWidth,
                                         height: cellHeight),
                           alive: true,
                           color: .yellow)
        
        self.addChild(maxCell)
    }
    
    // Update cells using Conway's Rules of Life:
    // 1) Any live cell with fewer than two live neighbors dies (underpopulation)
    // 2) Any live cell with two or three live neighbors lives on to the next generation
    // 3) Any live cell with more than three live neighbors dies (overpopulation)
    // 4) Any dead cell with exactly three live neighbors becomes a live cell (reproduction)
    // Must apply changes all at once for each generation, so will need copy of current cell grid
    func updateCells() {
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
    
    func makeGrid(xDimension: Int, yDimension: Int) -> [[Cell]] {
        var newGrid = [[Cell]]()
        for x in 0...xDimension {
            newGrid.append([Cell]())    // Create new Cell array for this xz
            for y in 0...yDimension {
                // The x and y coords are not at the edge of the cell; instead they are the center of it.
                // This can create confusion when attempting to position cells!
                let cellFrame = CGRect(x: cellMiddle(iteration: x, length: cellWidth), //Double(x)*cellWidth + cellWidth/2,
                                       y: cellMiddle(iteration: y, length: cellHeight), //Double(y)*cellHeight + cellHeight/2,
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
    
    func getGridIndicesFromPoint(at: CGPoint) -> (x: Int, y: Int) {
        let xIndex = Int(at.x / cellWidth)
        let yIndex = Int(at.y / cellHeight)
        
        return (xIndex, yIndex)
    }
        
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
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if self.previousTime == nil {
            self.previousTime = currentTime
        }
        
        if currentTime - self.previousTime >= self.updateInterval {
            self.updateCells()
            self.previousTime = currentTime
        }
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.spawnLiveCell(at: t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.spawnLiveCell(at: t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        
    }
    
    override func mouseUp(with event: NSEvent) {
        
    }

}
#endif

