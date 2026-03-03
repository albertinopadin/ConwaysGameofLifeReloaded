//
//  HLNode.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 3/2/26.
//  Copyright © 2026 Albertino Padin. All rights reserved.
//

import Foundation

public struct NodeKey: Hashable {
    let nw: ObjectIdentifier
    let ne: ObjectIdentifier
    let sw: ObjectIdentifier
    let se: ObjectIdentifier
}

public final class HLNode {
//    public static func computeHash(level: UInt64,
//                                   nw: HLNode? = nil,
//                                   ne: HLNode? = nil,
//                                   sw: HLNode? = nil,
//                                   se: HLNode? = nil) -> UInt64 {
//        return level &+ 2
//                     &+ 5131830419411 &* nw!.id
//                     &+ 3758991985019 &* ne!.id
//                     &+ 8973110871315 &* sw!.id
//                     &+ 4318490180473 &* se!.id
//    }
    
    /*
        ObjectIdentifier-based comparison helpers
        Slower due to re-hashing on every lookup, but here for completeness:
    */
    private static func objectIdComparison(lhs: HLNode, rhs: HLNode) -> Bool {
        if lhs.level != rhs.level { return false }
        if lhs.level == 0 { return lhs.population == rhs.population }
        return lhs.nw === rhs.nw && lhs.ne === rhs.ne && lhs.sw === rhs.sw && lhs.se === rhs.se
    }
    
    private func objectIdHash(into hasher: inout Hasher) {
        if level == 0 {
            hasher.combine(population)
        } else {
            hasher.combine(ObjectIdentifier(nw!))
            hasher.combine(ObjectIdentifier(ne!))
            hasher.combine(ObjectIdentifier(sw!))
            hasher.combine(ObjectIdentifier(se!))
        }
    }
    /* ==================================================================== */
    
    let id: Int
    let level: UInt64
    var population: UInt64
    let nw: HLNode?
    let ne: HLNode?
    let sw: HLNode?
    let se: HLNode?
    
    init(level: UInt64,
         id: Int? = nil,
         population: UInt64? = nil,
         nw: HLNode? = nil,
         ne: HLNode? = nil,
         sw: HLNode? = nil,
         se: HLNode? = nil) {
        
        if level == 0 {
            self.id = Int(population!)
        } else {
            self.id = id!
        }
        
        self.level = level
        self.nw = nw
        self.ne = ne
        self.sw = sw
        self.se = se
        
        if level == 0 {
            self.population = population!
        } else {
            self.population = (self.nw?.population ?? 0) +
                              (self.ne?.population ?? 0) +
                              (self.sw?.population ?? 0) +
                              (self.se?.population ?? 0)
        }
    }
    
}
