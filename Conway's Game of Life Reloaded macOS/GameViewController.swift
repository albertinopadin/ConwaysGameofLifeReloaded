//
//  GameViewController.swift
//  Conway's Game of Life Reloaded macOS
//
//  Created by Albertino Padin on 4/14/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit


class GameViewController: NSViewController, GameWindowDelegate {
    var gameScene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Present the scene
        let skView = self.view as! SKView
        gameScene = GameScene.newGameScene(size: skView.bounds.size)
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 120
        skView.presentScene(gameScene)
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.showsQuadCount = true
    }
    
    func toggleGameplay() {
        gameScene.toggleGameplay()
    }
    
    func setZoom(_ zoom: CGFloat) {
        gameScene.setZoom(zoom)
    }
    
    func setSpeed(_ speed: Double) {
        gameScene.setSpeed(speed)
    }
    
    func resetGame() {
        gameScene.resetGame()
    }
    
//    func setLiveRandomProbability(liveProbability: Double) {
//        gameScene.setLiveProbability(probability: liveProbability)
//    }
    
//    func randomizeGame() {
//        gameScene.randomizeGame()
//    }
    
    func randomizeGame(liveProbability: Double) {
        gameScene.randomizeGame(liveProbability: liveProbability)
    }
    
    func setSpaceshipType(type: SpaceshipType) {
        gameScene.setSpaceshipType(type: type)
    }
}
