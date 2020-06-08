//
//  GameSceneDelegate.swift
//  Conway's Game of Life Reloaded macOS
//
//  Created by Albertino Padin on 4/20/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

public protocol GameSceneDelegate: class {
    func setGeneration(_ generation: UInt64)
    func setSpeed(_ speed: Double)
}
