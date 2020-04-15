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

class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.newGameScene()
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}

