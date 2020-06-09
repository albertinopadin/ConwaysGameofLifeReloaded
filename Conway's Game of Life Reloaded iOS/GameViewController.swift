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

class GameViewController: UIViewController, GameSceneDelegate, UIPopoverPresentationControllerDelegate {
    var gameScene: GameScene!
    let pauseString = "Pause"
    let runString = "Run"
    let pinchGestureRecognizer = UIPinchGestureRecognizer()
    var previousZoomScale = CGFloat()
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    var speedVC: SpeedViewController?
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
        setUpSpeedViewController()
    }
    
    func setUpSpeedViewController() {
        speedVC = mainStoryboard.instantiateViewController(identifier: "speedViewController") as? SpeedViewController
        speedVC?.delegate = self
        speedVC?.modalPresentationStyle = .popover
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
    
    @IBAction func presentSpeedPopover(sender: UIBarButtonItem) {
        speedVC?.popoverPresentationController?.permittedArrowDirections = .up
        speedVC?.popoverPresentationController?.sourceView = self.view
        speedVC?.popoverPresentationController?.delegate = self
        let speedButtonView = sender.value(forKey: "view") as? UIView
        speedVC?.popoverPresentationController?.sourceRect = speedButtonView!.frame
        self.present(speedVC!, animated: true) {
            
        }
    }
    
    func setSpeed(_ speed: Double) {
        gameScene.setSpeed(speed)
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
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}
