//
//  SceneLocationEstimeate+Extensions.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import CoreLocation
import SceneKit

extension SceneLocationAREstimate {
    ///Compares the location's position to another position, to determine the translation between them
    public func locationTranslation(to position: SIMD3<Float>) -> LocationTranslation {
        return LocationTranslation(
            latitudeTranslation: Double(self.position.z - position.z),
            longitudeTranslation: Double(position.x - self.position.x),
            altitudeTranslation: Double(position.y - self.position.y))
    }

    ///Translates the location by comparing with a given position
    public func translatedLocation(to position: SIMD3<Float>) -> CLLocation {
        let translation = self.locationTranslation(to: position)
        let translatedLocation = self.location.translatedLocation(with: translation)

        return translatedLocation
    }
}
