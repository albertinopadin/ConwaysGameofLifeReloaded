//
//  CollectionExtension.swift
//  Conway's Game of Life Reloaded iOS
//
//  Created by Albertino Padin on 11/22/21.
//  Copyright © 2021 Albertino Padin. All rights reserved.
//

extension Collection {
    @inlinable
    @inline(__always)
    public func count(where test: (Element) throws -> Bool) rethrows -> Int {
        return try self.lazy.filter(test).count
    }
}
