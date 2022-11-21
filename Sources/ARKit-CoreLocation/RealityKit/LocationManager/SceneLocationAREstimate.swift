//
//  SceneLocationAREstimate.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import RealityFoundation
import CoreLocation

public class SceneLocationAREstimate {
    public let location: CLLocation
    public let position: SIMD3<Float>

    init(location: CLLocation, position: SIMD3<Float>) {
        self.location = location
        self.position = position
    }
}
