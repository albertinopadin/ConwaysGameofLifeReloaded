//
//  LifeAlgorithm.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 3/2/26.
//  Copyright © 2026 Albertino Padin. All rights reserved.
//

public protocol LifeAlgorithm {
    func update(generation: UInt64) -> UInt64
    func synchronizeState()
}
