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
//    let defaultXCells: Int = 50
//    let defaultYCells: Int = 50
//    let defaultXCells: Int = 100
//    let defaultYCells: Int = 100
//    let defaultXCells: Int = 200
//    let defaultYCells: Int = 200
//    let defaultXCells: Int = 400
//    let defaultYCells: Int = 400
//    static let defaultXCells: Int = 600
//    static let defaultYCells: Int = 600
    static let defaultXCells: Int = 800
    static let defaultYCells: Int = 800
//    let defaultXCells: Int = 1000
//    let defaultYCells: Int = 1000
    
    var xCells: Int
    var yCells: Int
    
    var gameRunning: Bool = false
    var gameDelegate: GameSceneDelegate?
    let cameraNode = SKCameraNode()
    
    var spaceshipType: SpaceshipType = .None
//    let backingNode = SKSpriteNode()
    
    class func newGameScene(size: CGSize,
                            xCells: Int = GameScene.defaultXCells,
                            yCells: Int = GameScene.defaultYCells) -> GameScene {
        let scene = GameScene(size: size, xCells: xCells, yCells: yCells)
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        return scene
    }
    
    init(size: CGSize, xCells: Int, yCells: Int) {
        self.xCells = xCells
        self.yCells = yCells
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setUpScene() {
        setUpCamera()
        (xCellsViz, yCellsViz) = getVisibleCellsXYBasedOnDeviceViewport(cellSize: defaultCellSize)
        cellGrid = CellGrid(xCells: xCells, yCells: yCells, cellSize: defaultCellSize)
        addCellGridToScene(cellGrid: cellGrid.grid)
        positionCameraAtCenter(camera: cameraNode, grid: cellGrid)
    }
    
    func setUpCamera() {
        self.addChild(cameraNode)
        self.camera = cameraNode
    }

    func getZoom() -> CGFloat {
        return cameraNode.xScale
    }

    func setZoom(_ zoom: CGFloat) {
        cameraNode.setScale(zoom)
    }
    
    func setSpeed(_ speed: Double) {
        // updateInterval = 1/speed
        updateInterval = (1/speed)/4  // TODO: I have no idea why this works. Crazy! Now this runs at 60FPS
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
        cellGrid.lazy.joined().forEach({ self.addChild($0.node) })
    }
    
    @inlinable
    @inline(__always)
    public final func timeit(body: ()->()) -> UInt64 {
        let start = DispatchTime.now().uptimeNanoseconds
        body()
        return DispatchTime.now().uptimeNanoseconds - start
    }
    
    // Called every 16ms, or every 8ms on ProMotion devices:
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if previousTime == nil {
            previousTime = currentTime
        }

        if gameRunning && (currentTime - previousTime >= updateInterval) {
//            let generation = cellGrid.updateCells()
//            previousTime = currentTime
//            gameDelegate?.setGeneration(generation)

            let t = timeit {
                let generation = cellGrid.updateCells()
                previousTime = currentTime
                gameDelegate?.setGeneration(generation)
            }
            print("Run time: \(Double(t)/1_000_000) ms")
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
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isMouseEventInsideView(event: event) {
            if spaceshipType != .None {
                // What makes sense to do here? Is there a mouseUp action?
                cellGrid.shadowSpaceship(at: event.location(in: self), type: spaceshipType)
            } else {
                cellGrid.touchedCell(at: event.location(in: self), gameRunning: gameRunning)
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
        return self.view!.hitTest(event.locationInWindow) != nil
    }

}
#endif

