//
//  HLNode.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 3/2/26.
//  Copyright © 2026 Albertino Padin. All rights reserved.
//

import Foundation

public struct NodeKey: Hashable {
    let population: UInt64
    let nw: ObjectIdentifier?
    let ne: ObjectIdentifier?
    let sw: ObjectIdentifier?
    let se: ObjectIdentifier?
    
    init(population: UInt64,
         nw: ObjectIdentifier? = nil,
         ne: ObjectIdentifier? = nil,
         sw: ObjectIdentifier? = nil,
         se: ObjectIdentifier? = nil) {
        self.population = population
        self.nw = nw
        self.ne = ne
        self.sw = sw
        self.se = se
    }
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
    
    public let id: NodeKey
    public let level: UInt64
    public var population: UInt64
    public var nw: HLNode?
    public var ne: HLNode?
    public var sw: HLNode?
    public var se: HLNode?
    
    public var result: HLNode?  // cached nextGeneration output
    
    init(level: UInt64,
         id: NodeKey? = nil,
         population: UInt64? = nil,
         nw: HLNode? = nil,
         ne: HLNode? = nil,
         sw: HLNode? = nil,
         se: HLNode? = nil) {
        
        if level == 0, let population {
            self.id = NodeKey(population: population)
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
    
    public func synchronizePopulation() {
        self.population = (self.nw?.population ?? 0) +
                          (self.ne?.population ?? 0) +
                          (self.sw?.population ?? 0) +
                          (self.se?.population ?? 0)
    }
}
