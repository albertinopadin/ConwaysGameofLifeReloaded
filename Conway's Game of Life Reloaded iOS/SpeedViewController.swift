//
//  SpeedViewController.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 6/8/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import UIKit

class SpeedViewController: UIViewController {

    var delegate: GameSceneDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func setSpeed(_ sender: UISlider) {
        delegate?.setSpeed(Double(sender.value))
    }

}
