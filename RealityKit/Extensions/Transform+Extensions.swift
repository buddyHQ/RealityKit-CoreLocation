//
//  Transform+Extensions.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import RealityFoundation

@available(iOS 13.0, *)
public extension Transform {
    // From: https://stackoverflow.com/questions/50236214/arkit-eulerangles-of-transform-matrix-4x4
    var eulerAngles: SIMD3<Float> {
        let matrix = matrix
        return .init(
            x: asin(-matrix[2][1]),
            y: atan2(matrix[2][0], matrix[2][2]),
            z: atan2(matrix[0][1], matrix[1][1])
        )
    }
}
