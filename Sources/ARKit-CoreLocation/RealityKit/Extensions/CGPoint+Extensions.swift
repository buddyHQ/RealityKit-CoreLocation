//
//  CGPoint+Extensions.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import UIKit
import SceneKit

extension CGPoint {
    static func pointWithVector(vector: SIMD3<Float>) -> CGPoint {
        return CGPoint(x: CGFloat(vector.x), y: CGFloat(0 - vector.z))
    }
}
