//
//  SceneLocationARManager.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import Foundation
import ARKit
import CoreLocation
import MapKit


protocol SceneLocationARManagerDelegate: AnyObject {
    var scenePosition: SIMD3<Float>? { get }

    func confirmLocationOfDistantLocationEntitys()
    func updatePositionAndScaleOfLocationEntitys()

    func didAddSceneLocationEstimate(position: SIMD3<Float>, location: CLLocation)
    func didRemoveSceneLocationEstimate(position: SIMD3<Float>, location: CLLocation)
}

public final class SceneLocationARManager {
    weak var sceneLocationDelegate: SceneLocationARManagerDelegate?

    public var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate
    public let locationManager = LocationManager()

    var sceneLocationEstimates = [SceneLocationAREstimate]()

    var updateEstimatesTimer: Timer?

    /// The best estimation of location that has been taken
    /// This takes into account horizontal accuracy, and the time at which the estimation was taken
    /// favouring the most accurate, and then the most recent result.
    /// This doesn't indicate where the user currently is.
    public var bestLocationEstimate: SceneLocationAREstimate? {
        let sortedLocationEstimates = sceneLocationEstimates.sorted(by: {
            if $0.location.horizontalAccuracy == $1.location.horizontalAccuracy {
                return $0.location.timestamp > $1.location.timestamp
            }

            return $0.location.horizontalAccuracy < $1.location.horizontalAccuracy
        })

        return sortedLocationEstimates.first
    }

    public var currentLocation: CLLocation? {
        if locationEstimateMethod == .coreLocationDataOnly { return locationManager.currentLocation }

        guard let bestEstimate = bestLocationEstimate,
            let position = sceneLocationDelegate?.scenePosition else { return nil }

        return bestEstimate.translatedLocation(to: position)
    }

    init() {
        locationManager.delegate = self
    }

    deinit {
        pause()
    }

    @objc
    func updateLocationData() {
        removeOldLocationEstimates()

        sceneLocationDelegate?.confirmLocationOfDistantLocationEntitys()
        sceneLocationDelegate?.updatePositionAndScaleOfLocationEntitys()
    }

    ///Adds a scene location estimate based on current time, camera position and location from location manager
    func addSceneLocationEstimate(location: CLLocation) {
        guard let position = sceneLocationDelegate?.scenePosition else { return }

        sceneLocationEstimates.append(SceneLocationAREstimate(location: location, position: position))

        sceneLocationDelegate?.didAddSceneLocationEstimate(position: position, location: location)
    }

    func removeOldLocationEstimates() {
        guard let currentScenePosition = sceneLocationDelegate?.scenePosition else { return }
        removeOldLocationEstimates(currentScenePosition: currentScenePosition)
    }

    func removeOldLocationEstimates(currentScenePosition: SIMD3<Float>) {
        let currentPoint = CGPoint.pointWithVector(vector: currentScenePosition)

        sceneLocationEstimates = sceneLocationEstimates.filter {
            if #available(iOS 11.0, *) {
                let radiusContainsPoint = currentPoint.radiusContainsPoint(
                    radius: CGFloat(SceneLocationView.sceneLimit),
                    point: CGPoint.pointWithVector(vector: $0.position))

                if !radiusContainsPoint {
                    sceneLocationDelegate?.didRemoveSceneLocationEstimate(position: $0.position, location: $0.location)
                }

                return radiusContainsPoint
            } else {
                return false
            }
        }
    }

}

public extension SceneLocationARManager {
    func run() {
        pause()
        if #available(iOS 11.0, *) {
            updateEstimatesTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.updateLocationData()
            }
        } else {
            assertionFailure("Needs iOS 9 and 10 support")
        }
    }

    func pause() {
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = nil
    }
}

extension SceneLocationARManager: LocationManagerDelegate {

    func locationManagerDidUpdateLocation(_ locationManager: LocationManager,
                                          location: CLLocation) {
        addSceneLocationEstimate(location: location)
    }
}
