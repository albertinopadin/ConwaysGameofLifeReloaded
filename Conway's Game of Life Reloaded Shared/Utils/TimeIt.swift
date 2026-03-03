//
//  TimeIt.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 6/18/22.
//  Copyright © 2022 Albertino Padin. All rights reserved.
//

import Dispatch


@inlinable
@inline(__always)
public func timeit(body: ()->()) -> UInt64 {
    let start = DispatchTime.now().uptimeNanoseconds
    body()
    return DispatchTime.now().uptimeNanoseconds - start
}
