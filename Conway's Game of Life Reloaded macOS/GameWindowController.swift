//
//  GameWindowController.swift
//  Conway's Game of Life Reloaded macOS
//
//  Created by Albertino Padin on 4/20/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import Cocoa

class GameWindowController: NSWindowController, GameSceneDelegate {
    var gameViewController: GameViewController?
    let pauseString = "Pause"
    let runString = "Run"
    @IBOutlet weak var generationsLabel: NSTextField!
    @IBOutlet weak var toggleGameplayButton: NSButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        shouldCascadeWindows = true
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        toggleGameplayButton.title = runString
        generationsLabel.stringValue = "0"
        gameViewController = self.contentViewController as? GameViewController
        gameViewController?.gameScene.gameDelegate = self
    }
    
    @IBAction func toggleGameplay(sender: NSButton) {
        gameViewController?.toggleGameplay()
        if toggleGameplayButton.title == runString {
            toggleGameplayButton.title = pauseString
        } else {
            toggleGameplayButton.title = runString
        }
    }
    
    @IBAction func resetGame(sender: NSButton) {
        gameViewController?.resetGame()
        if toggleGameplayButton.title == pauseString {
            toggleGameplayButton.title = runString
        }
    }
    
    func setGeneration(_ generation: UInt64) {
        generationsLabel.stringValue = "\(generation)"
    }
}
