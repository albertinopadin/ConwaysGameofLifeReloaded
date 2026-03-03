//
//  NaiveConcurrent.swift
//  Conway's Game of Life Reloaded
//
//  Created by Albertino Padin on 3/2/26.
//  Copyright © 2026 Albertino Padin. All rights reserved.
//

import Foundation

public final class NaiveConcurrent: LifeAlgorithm {
    let updateQueue: DispatchQueue
    
    let xCount: Int
    let yCount: Int
    let grid: ContiguousArray<ContiguousArray<Cell>> // Note: if both this and CellGrid call sync on this queue might deadlock
    
    init(grid: ContiguousArray<ContiguousArray<Cell>>, xCount: Int, yCount: Int, queue: DispatchQueue) {
        self.grid = grid
        self.xCount = xCount
        self.yCount = yCount
        self.updateQueue = queue
    }
    
    public func update(generation: UInt64) -> UInt64 {
        // 3.7 - 4 ms
    //        // Prepare update:
    //        updateQueue.sync {
    //            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                    self.grid[x][y].prepareUpdate()
    //                }
    //            }
    //        }
    //
    //        // Update
    //        // Doing concurrentPerform on both inner and outer loops doubles FPS:
    //        updateQueue.sync {
    //            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                    self.grid[x][y].update()
    //                }
    //            }
    //        }
        
        
    //        self.grid.withUnsafeBufferPointer { buffer in
    //            // Prepare update:
    //            updateQueue.sync {
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                        buffer[x][y].prepareUpdate()
    //                    }
    //                }
    //            }
    //
    //            // Update
    //            // Doing concurrentPerform on both inner and outer loops doubles FPS:
    //            updateQueue.sync {
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                        buffer[x][y].update()
    //                    }
    //                }
    //            }
    //        }
        
        
        // 3.6 - 4 ms
        // Prepare update:
    //        updateQueue.sync {
    //            DispatchQueue.concurrentPerform(iterations: self.halfCountX) { x in
    //                DispatchQueue.concurrentPerform(iterations: self.halfCountY) { y in
    //                    self.grid[x][y].prepareUpdate()
    //                    self.grid[x + self.halfCountX][y].prepareUpdate()
    //                    self.grid[x][y + self.halfCountY].prepareUpdate()
    //                    self.grid[x + self.halfCountX][y + self.halfCountY].prepareUpdate()
    //                }
    //            }
    //        }
    //
    //        // Update
    //        // Doing concurrentPerform on both inner and outer loops doubles FPS:
    //        updateQueue.sync {
    //            DispatchQueue.concurrentPerform(iterations: self.halfCountX) { x in
    //                DispatchQueue.concurrentPerform(iterations: self.halfCountY) { y in
    //                    self.grid[x][y].update()
    //                    self.grid[x + self.halfCountX][y].update()
    //                    self.grid[x][y + self.halfCountY].update()
    //                    self.grid[x + self.halfCountX][y + self.halfCountY].update()
    //                }
    //            }
    //        }
        
        
        // 2.8 - 3 ms:
        // This also seems to have a similar FPS and Frametime as double concurrentPerform:
        // Prepare update:
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                self.grid[x].forEach { $0.prepareUpdate() }
            }
        }

        // Update
        updateQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
                self.grid[x].lazy.filter({ $0.needsUpdate() }).forEach { $0.update() }
    //                self.grid[x].forEach { $0.update() }
            }
        }
        
        
    //        ************************************************************************************
        
        
    //        updateQueue.sync {
    //            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                self.grid.withUnsafeBufferPointer { buffer in
    //                    buffer[x].forEach { $0.prepareUpdate() }
    //                }
    //            }
    //        }
    //
    //        // Update
    //        updateQueue.sync {
    //            DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                self.grid.withUnsafeBufferPointer { buffer in
    //                    self.grid[x].lazy.filter({ $0.needsUpdate() }).forEach { $0.update() }
    //                }
    //            }
    //        }
        
        
    //        updateQueue.sync {
    //            self.grid.withUnsafeBufferPointer { buffer in
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    buffer[x].forEach { $0.prepareUpdate() }
    //                }
    //            }
    //        }
    //
    //        // Update
    //        updateQueue.sync {
    //            self.grid.withUnsafeBufferPointer { buffer in
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    self.grid[x].lazy.filter({ $0.needsUpdate() }).forEach { $0.update() }
    //                }
    //            }
    //        }
        
        
    //        self.grid.withUnsafeBufferPointer { buffer in
    //            updateQueue.sync {
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                        buffer[x][y].prepareUpdate()
    //                    }
    //                }
    //            }
    //
    //            updateQueue.sync {
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                        buffer[x][y].update()
    //                    }
    //                }
    //            }
    //        }
        
        
        
    //        updateQueue.sync {
    //            self.grid.withUnsafeBufferPointer { buffer in
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                        buffer[x][y].prepareUpdate()
    //                    }
    //                }
    //            }
    //        }
    //
    //        updateQueue.sync {
    //            self.grid.withUnsafeBufferPointer { buffer in
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    DispatchQueue.concurrentPerform(iterations: self.yCount) { y in
    //                        buffer[x][y].update()
    //                    }
    //                }
    //            }
    //        }
        
        
    //        grid.withUnsafeBufferPointer { xBuffer in
    //            updateQueue.sync {
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    xBuffer[x].withUnsafeBufferPointer { yBuffer in
    //                        yBuffer.forEach { $0.prepareUpdate() }
    //                    }
    //                }
    //            }
    //
    //            // Update
    //            updateQueue.sync {
    //                DispatchQueue.concurrentPerform(iterations: self.xCount) { x in
    //                    xBuffer[x].withUnsafeBufferPointer { yBuffer in
    //                        yBuffer.lazy.filter({ $0.needsUpdate() }).forEach { $0.update() }
    //                    }
    //                }
    //            }
    //        }
        
        return generation + 1
    }

}
