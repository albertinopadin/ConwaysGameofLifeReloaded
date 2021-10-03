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
    let defaultSliderValue: CGFloat = 300.0
    @IBOutlet weak var generationsLabel: NSTextField!
    @IBOutlet weak var toggleGameplayButton: NSButton!
    @IBOutlet weak var spaceshipButton: NSPopUpButton!
    
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
        spaceshipButton.removeAllItems()
        spaceshipButton.addItems(withTitles: getSpaceshipTitles())
        spaceshipButton.selectItem(at: 0)
    }
    
    
    func getSpaceshipTitles() -> [String] {
        return ["None", "Square", "Glider"]
    }
    
    @IBAction func toggleGameplay(sender: NSButton) {
        gameViewController?.toggleGameplay()
        if toggleGameplayButton.title == runString {
            toggleGameplayButton.title = pauseString
        } else {
            toggleGameplayButton.title = runString
        }
    }
    
    @IBAction func setZoom(sender: NSSlider) {
        let zoom = convertSliderValueToZoom(CGFloat(sender.floatValue))
        gameViewController?.setZoom(zoom)
    }
    
    func convertSliderValueToZoom(_ value: CGFloat) -> CGFloat {
        return defaultSliderValue/value
    }
    
    func setSpeed(_ speed: Double) {
         gameViewController?.setSpeed(speed)
    }
    
    @IBAction func setSpeed(sender: NSSlider) {
       setSpeed(sender.doubleValue)
    }
    
    @IBAction func resetGame(sender: NSButton) {
        gameViewController?.resetGame()
        if toggleGameplayButton.title == pauseString {
            toggleGameplayButton.title = runString
        }
    }
    
    @IBAction func randomizeGame(sender: NSButton) {
        gameViewController?.randomizeGame()
        if toggleGameplayButton.title == pauseString {
            toggleGameplayButton.title = runString
        }
    }
    
    func setGeneration(_ generation: UInt64) {
        generationsLabel.stringValue = "\(generation)"
    }
    
    @IBAction func spaceshipSelectionDidChange(_ sender: NSPopUpButton) {
        if sender.selectedItem == spaceshipButton.item(at: 0) {
            gameViewController?.setSpaceshipType(type: .None)
        } else if sender.selectedItem == spaceshipButton.item(at: 1) {
            gameViewController?.setSpaceshipType(type: .Square)
        } else {
            gameViewController?.setSpaceshipType(type: .Glider)
        }
    }
}
