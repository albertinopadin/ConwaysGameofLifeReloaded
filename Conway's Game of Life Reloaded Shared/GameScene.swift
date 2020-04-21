//
//  GameScene.swift
//  Conway's Game of Life Reloaded Shared
//
//  Created by Albertino Padin on 4/14/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var cellGrid: CellGrid!
    var updateInterval: Double = 0.25
    var previousTime: TimeInterval!

    // Need to initialize on sceneDidLoad!!!
    var xDimension: Int = 0
    var yDimension: Int = 0
    
    var dScale: Int = 23
    
    var gameRunning: Bool = false
    var gameDelegate: GameSceneDelegate?
    
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
        (xDimension, yDimension) = initDimensionsBasedOnDeviceViewport()
        cellGrid = CellGrid(xDimension: xDimension, yDimension: yDimension)
        addCellGridToScene(cellGrid: cellGrid.grid)
    }
    
    func initDimensionsBasedOnDeviceViewport() -> (Int, Int) {
        let xDim = Int(self.frame.size.width / CGFloat(dScale))
        let yDim = Int(self.frame.size.height / CGFloat(dScale))
        return (xDim, yDim)
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        setUpScene()
    }
    #endif
    
    func addCellGridToScene(cellGrid: [[Cell]]) {
        for cellArray in cellGrid {
            for cell in cellArray {
                self.addChild(cell)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if previousTime == nil {
            previousTime = currentTime
        }
        
        if gameRunning && currentTime - previousTime >= updateInterval {
            let generation = cellGrid.updateCells()
            previousTime = currentTime
            gameDelegate?.setGeneration(generation)
        }
    }
    
    func toggleGameplay() {
        gameRunning.toggle()
    }
    
    func resetGame() {
        gameRunning = false
        cellGrid.reset()
        gameDelegate?.setGeneration(0)
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            cellGrid.spawnLiveCell(at: t.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            cellGrid.spawnLiveCell(at: t.location(in: self))
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
        if isMouseEventInsideView(event: event) {
            cellGrid.spawnLiveCell(at: event.location(in: self))
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isMouseEventInsideView(event: event) {
            cellGrid.spawnLiveCell(at: event.location(in: self))
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        
    }
    
    func isMouseEventInsideView(event: NSEvent) -> Bool {
        return self.view?.hitTest(event.locationInWindow) != nil
    }

}
#endif

