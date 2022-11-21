//
//  SIMD3+Extensions.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import Foundation

public extension SIMD3<Float> {
    ///Calculates distance between vectors
    ///Doesn't include the y axis, matches functionality of CLLocation 'distance' function.
    func distance(to anotherVector: SIMD3<Float>) -> Float {
        return sqrt(pow(anotherVector.x - x, 2) + pow(anotherVector.z - z, 2))
    }
}
