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
    var xCellsViz: Int = 0
    var yCellsViz: Int = 0
    
    let defaultCellSize: CGFloat = 23.0
    let defaultXCells: Int = 400
    let defaultYCells: Int = 400
//    let defaultXCells: Int = 200
//    let defaultYCells: Int = 200
    
    var gameRunning: Bool = false
    var gameDelegate: GameSceneDelegate?
    let cameraNode = SKCameraNode()
    
    var spaceshipType: SpaceshipType = .None
//    let backingNode = SKSpriteNode()
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Failed to load GameScene.sks")
            abort()
        }

        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
//        scene.backgroundColor = .black
//        scene.blendMode = .replace
//        scene.shouldRasterize = true
        scene.shouldRasterize = false
        return scene
    }
    
    func setUpScene() {
        setUpCamera()
        (xCellsViz, yCellsViz) = getVisibleCellsXYBasedOnDeviceViewport(cellSize: defaultCellSize)
        cellGrid = CellGrid(xCells: defaultXCells, yCells: defaultYCells, cellSize: defaultCellSize)
        addCellGridToScene(cellGrid: cellGrid.grid)
        positionCameraAtCenter(camera: cameraNode, grid: cellGrid)
        
//        let w = CGFloat(defaultXCells) * defaultCellSize
//        let h = CGFloat(defaultYCells) * defaultCellSize
//        let bgSize = CGSize(width: w, height: h)
//        backingNode.size = bgSize
//        backingNode.position = CGPoint(x: bgSize.width/2, y: bgSize.height/2)
//        backingNode.color = .black
//        backingNode.blendMode = .replace
//        self.addChild(backingNode)
    }
    
    func setUpCamera() {
//        cameraNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
//        cameraNode.position = .zero
//        cameraNode.position = CGPoint(x: -self.frame.midX, y: -self.frame.midY)
        self.addChild(cameraNode)
        self.camera = cameraNode
    }

    func getZoom() -> CGFloat {
        return cameraNode.xScale
    }

    func setZoom(_ zoom: CGFloat) {
        cameraNode.setScale(zoom)
    }
    
//    func getZoom() -> CGFloat {
//        return backingNode.xScale
//    }
//
//    func setZoom(_ zoom: CGFloat) {
//        backingNode.setScale(1/zoom)
//    }
    
//    func getZoom() -> CGFloat {
//        return self.xScale
//    }
//
//    func setZoom(_ zoom: CGFloat) {
//        self.setScale(1/zoom)
//    }
    
    func setSpeed(_ speed: Double) {
        updateInterval = 1/speed
        print("Update interval: \(updateInterval)")
    }
    
    func getVisibleCellsXYBasedOnDeviceViewport(cellSize: CGFloat) -> (Int, Int) {
        let xCells = Int(self.frame.size.width / cellSize)
        let yCells = Int(self.frame.size.height / cellSize)
        return (xCells, yCells)
    }
    
    func positionCameraAtCenter(camera: SKCameraNode, grid: CellGrid) {
        let (gridX, gridY) = grid.getPointDimensions()
        camera.position = CGPoint(x: gridX / 2, y: gridY / 2)
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
    
    func addCellGridToScene(cellGrid: ContiguousArray<ContiguousArray<Cell>>) {
        for cellArray in cellGrid {
            for cell in cellArray {
                self.addChild(cell.node)
            }
        }
        
//        for cellArray in cellGrid {
//            for cell in cellArray {
//                backingNode.addChild(cell.node)
//            }
//        }
    }
    
    // Called every 16ms, or every 8ms on ProMotion devices:
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if previousTime == nil {
            previousTime = currentTime
        }
        
        if gameRunning && (currentTime - previousTime >= updateInterval) {
            let generation = cellGrid.updateCells()
            previousTime = currentTime
            gameDelegate?.setGeneration(generation)
        }
    }
    
//    override func didFinishUpdate() {
//        cellGrid.prepareUpdateCells()
//    }
    
    func toggleGameplay() {
        gameRunning.toggle()
    }
    
    func resetGame() {
        gameRunning = false
        cellGrid.reset()
        gameDelegate?.setGeneration(0)
    }
    
//    func setLiveProbability(probability: Double) {
//        cellGrid.setLiveProbability(probability)
//    }
    
//    func randomizeGame() {
//        gameRunning = false
//        cellGrid.reset()
//        cellGrid.randomState()
//        gameDelegate?.setGeneration(0)
//    }
    
    func randomizeGame(liveProbability: Double) {
        gameRunning = false
        cellGrid.reset()
        cellGrid.randomState(liveProbability: liveProbability)
        gameDelegate?.setGeneration(0)
    }
    
    func setSpaceshipType(type: SpaceshipType) {
        spaceshipType = type
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            cellGrid.touchedCell(at: t.location(in: self), gameRunning: gameRunning)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            cellGrid.touchedCell(at: t.location(in: self), gameRunning: gameRunning)
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
    override func mouseMoved(with event: NSEvent) {
        print("Mouse Moved!")
        if isMouseEventInsideView(event: event) {
            if spaceshipType != .None {
                cellGrid.shadowSpaceship(at: event.location(in: self), type: spaceshipType)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        if isMouseEventInsideView(event: event) {
            if spaceshipType != .None {
                // Perhaps should put this in mouseUp action if that exists:
//                cellGrid.placeSpaceship(at: event.location(in: self), type: spaceshipType)
            } else {
                cellGrid.touchedCell(at: event.location(in: self), gameRunning: gameRunning)
//                let eventLocation = event.location(in: self)
//                let touchPoint = CGPoint(x: eventLocation.x * getZoom(), y: eventLocation.y * getZoom())
//                cellGrid.touchedCell(at: touchPoint)
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        print("Mouse Dragged!")
        if isMouseEventInsideView(event: event) {
            if spaceshipType != .None {
                // What makes sense to do here? Is there a mouseUp action?
                cellGrid.shadowSpaceship(at: event.location(in: self), type: spaceshipType)
            } else {
                cellGrid.touchedCell(at: event.location(in: self), gameRunning: gameRunning)
//                let eventLocation = event.location(in: self)
//                let touchPoint = CGPoint(x: eventLocation.x * getZoom(), y: eventLocation.y * getZoom())
//                cellGrid.touchedCell(at: touchPoint)
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if isMouseEventInsideView(event: event) {
            if spaceshipType != .None {
                cellGrid.placeSpaceship(at: event.location(in: self), type: spaceshipType)
            }
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if isMouseEventInsideView(event: event) {
            cellGrid.touchedCell(at: event.location(in: self), gameRunning: gameRunning, withAltAction: true)
        }
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        if isMouseEventInsideView(event: event) {
            cellGrid.touchedCell(at: event.location(in: self), gameRunning: gameRunning, withAltAction: true)
        }
    }
    
    func isMouseEventInsideView(event: NSEvent) -> Bool {
        return self.view?.hitTest(event.locationInWindow) != nil
    }

}
#endif

