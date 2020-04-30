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
        
        gameScene = GameScene.newGameScene()
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(gameScene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
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
}
