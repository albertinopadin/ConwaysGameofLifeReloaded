//
//  Hashlife.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 3/2/26.
//  Copyright © 2026 Albertino Padin. All rights reserved.
//

import Foundation

// TODO:
public final class Hashlife: LifeAlgorithm {
    private var canonicalNodes: [Int: HLNode] = [:]
    
    public let alive = HLNode(level: 0, id: 1, population: 1)
    public let dead  = HLNode(level: 0, id: 0, population: 0)
    
    init() {
        canonicalNodes[dead.id] = dead
        canonicalNodes[alive.id] = alive
    }
    
    // This should only apply to leaf (level 0) nodes in the quadtree:
    func applyLifeRules(for node: HLNode, neighbors: [HLNode]) -> HLNode {
        let liveNeighbors = neighbors.map((\.population)).reduce(0, +)
        let alive = liveNeighbors == 3 || (liveNeighbors == 2 && node.population == 1)
        node.population = alive ? 1 : 0
        return node
    }
    
    // This should only be called on level 2 nodes:
    func applyLifeRules4x4(node: HLNode) -> HLNode {
        let nw = applyLifeRules(for: node.nw!.se!, neighbors: [node.nw!.nw!,
                                                               node.nw!.ne!,
                                                               node.nw!.sw!,
                                                               node.ne!.nw!,
                                                               node.ne!.sw!,
                                                               node.sw!.nw!,
                                                               node.sw!.ne!,
                                                               node.se!.nw!])
        
        let ne = applyLifeRules(for: node.ne!.sw!, neighbors: [node.ne!.nw!,
                                                               node.ne!.ne!,
                                                               node.ne!.se!,
                                                               node.se!.nw!,
                                                               node.se!.ne!,
                                                               node.sw!.ne!,
                                                               node.nw!.ne!,
                                                               node.nw!.se!])
        
        let sw = applyLifeRules(for: node.sw!.ne!, neighbors: [node.sw!.nw!,
                                                               node.sw!.sw!,
                                                               node.sw!.se!,
                                                               node.se!.nw!,
                                                               node.se!.sw!,
                                                               node.ne!.sw!,
                                                               node.nw!.se!,
                                                               node.nw!.sw!])
        
        let se = applyLifeRules(for: node.se!.nw!, neighbors: [node.se!.ne!,
                                                               node.se!.se!,
                                                               node.se!.sw!,
                                                               node.ne!.sw!,
                                                               node.ne!.se!,
                                                               node.nw!.se!,
                                                               node.sw!.ne!,
                                                               node.sw!.se!])
        
        return join(nw: nw, ne: ne, sw: sw, se: se)
    }
    
    func join(nw: HLNode, ne: HLNode, sw: HLNode, se: HLNode) -> HLNode {
        let key = NodeKey(nw: ObjectIdentifier(nw),
                          ne: ObjectIdentifier(ne),
                          sw: ObjectIdentifier(sw),
                          se: ObjectIdentifier(se))
        
        if let existing = canonicalNodes[key.hashValue] {
            return existing
        }
        
        let node = HLNode(level: nw.level + 1, id: key.hashValue, nw: nw, ne: ne, sw: sw, se: se)
        canonicalNodes[key.hashValue] = node
        return node
    }
    
    public func update(generation: UInt64) -> UInt64 {
        return 0
    }
}
