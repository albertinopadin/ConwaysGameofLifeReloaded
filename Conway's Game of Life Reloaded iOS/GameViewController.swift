//
//  GameViewController.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 4/14/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, GameSceneDelegate {
    var gameScene: GameScene!
    let pauseString = "Pause"
    let runString = "Run"
    let pinchGestureRecognizer = UIPinchGestureRecognizer()
    var previousZoomScale = CGFloat()
    @IBOutlet weak var generationsLabel: UIBarButtonItem!
    @IBOutlet weak var toggleGameplayButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameScene = GameScene.newGameScene()
        gameScene.gameDelegate = self

        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(gameScene)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
        skView.ignoresSiblingOrder = true
        
        setUpPinchGestureRecognizer()
    }
    
    func setUpPinchGestureRecognizer() {
        pinchGestureRecognizer.addTarget(self, action: #selector(pinchGestureAction(_:)))
        self.view.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    @objc func pinchGestureAction(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            previousZoomScale = gameScene.getZoom()
        }
        
        let relativeZoom = previousZoomScale * 1/sender.scale
        gameScene.setZoom(relativeZoom)
    }
    
    @IBAction func toggleGameplay(sender: UIBarButtonItem) {
        gameScene.toggleGameplay()
        if toggleGameplayButton.title == runString {
            toggleGameplayButton.title = pauseString
        } else {
            toggleGameplayButton.title = runString
        }
    }
    
    @IBAction func resetGame(sender: UIBarButtonItem) {
        gameScene.resetGame()
        if toggleGameplayButton.title == pauseString {
            toggleGameplayButton.title = runString
        }
    }
    
    func setGeneration(_ generation: UInt64) {
        generationsLabel.title = "\(generation)"
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
