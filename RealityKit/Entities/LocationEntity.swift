//
//  LocationEntity.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import Foundation
import RealityKit
import ARKit

@available(iOS 13.0, *)
open class AnnotationEntity: Entity, HasModel {
    public var view: UIView?
    public var image: UIImage?
    public var layer: CALayer?

    public init(view: UIView?, image: UIImage?, layer: CALayer? = nil) {
        super.init()
        self.view = view
        self.image = image
        self.layer = layer
    }
    
    required public init() {
        fatalError("init() has not been implemented")
    }
}

@available(iOS 13.0, *)
open class LocationEntity: Entity, HasModel {
    // FIXME: figure out why this is hardcoded and why it would ever be different from the scene's sitting?
    /// This seems like it should be a bug? Why is it hardcoded? Why would it ever be different from the scene's setting?
    var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate

    /// Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation!

    /// A general purpose tag that can be used to find nodes already added to a SceneLocationView
    public var tag: String?

    /// Whether the location of the node has been confirmed.
    /// This is automatically set to true when you create a node using a location.
    /// Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    /// except when the locationEstimateMethod is set to use Core Location data only,
    /// as then it becomes true immediately.
    public var locationConfirmed: Bool {
        return location != nil
    }

    /// Whether a node's position should be adjusted on an ongoing basis
    /// based on its given location.
    /// This only occurs when a node's location is within 100m of the user.
    /// Adjustment doesn't apply to nodes without a confirmed location.
    /// When this is set to false, the result is a smoother appearance.
    /// When this is set to true, this means a node may appear to jump around
    /// as the user's location estimates update,
    /// but the position is generally more accurate.
    /// Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true

    /// Whether a node's position and scale should be updated automatically on a continual basis.
    /// This should only be set to false if you plan to manually update position and scale
    /// at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true

    /// Whether the node should be scaled relative to its distance from the camera
    /// Default value (false) scales it to visually appear at the same size no matter the distance
    /// Setting to true causes annotation nodes to scale like a regular node
    /// Scaling relative to distance may be useful with local navigation-based uses
    /// For landmarks in the distance, the default is correct
    public var scaleRelativeToDistance = false

    /// Whether the node should appear at the same altitude of the user
    /// May be useful when you don't know the real altitude of the node
    /// When set to true, the node will stay at the same altitude of the user
    public var ignoreAltitude = false

    /// The scheme to use for scaling
    public var scalingScheme: ScalingScheme = .normal

    public init(location: CLLocation?, tag: String? = nil) {
        self.location = location
        self.tag = tag
        super.init()
    }
    
    required public init() {
        fatalError("init() has not been implemented")
    }
    
    internal func location(_ bestLocationEstimate: SceneLocationAREstimate?) -> CLLocation {
        if locationConfirmed || locationEstimateMethod == .coreLocationDataOnly {
            return location!
        }

        if let bestLocationEstimate = bestLocationEstimate,
            location == nil || bestLocationEstimate.location.horizontalAccuracy < location!.horizontalAccuracy {
            return bestLocationEstimate.translatedLocation(to: position)
        } else {
            return location!
        }
    }

    internal func adjustedDistance(setup: Bool, position: SIMD3<Float>, locationNodeLocation: CLLocation,
                                   locationManager: SceneLocationARManager) -> CLLocationDistance {
        guard let location = locationManager.currentLocation else {
            return 0.0
        }

        // Position is set to a position coordinated via the current position
        let distance = self.location(locationManager.bestLocationEstimate).distance(from: location)

        var locationTranslation = location.translation(toLocation: locationNodeLocation)
        locationTranslation.altitudeTranslation = ignoreAltitude ? 0 : locationTranslation.altitudeTranslation

        let adjustedDistance: CLLocationDistance
        if locationConfirmed && (distance > 100 || continuallyAdjustNodePositionWhenWithinRange || setup) {
            if distance > 100 {
                //If the item is too far away, bring it closer and scale it down
                let scale = 100 / Float(distance)

                adjustedDistance = distance * Double(scale)

                let adjustedTranslation = SIMD3<Float>( x: Float(locationTranslation.longitudeTranslation) * scale,
                                                      y: Float(locationTranslation.altitudeTranslation) * scale,
                                                      z: Float(locationTranslation.latitudeTranslation) * scale)
                self.position = SIMD3<Float>( x: position.x + adjustedTranslation.x,
                                            y: position.y + adjustedTranslation.y,
                                            z: position.z - adjustedTranslation.z)
                self.scale = SIMD3<Float>(x: scale, y: scale, z: scale)
            } else {
                adjustedDistance = distance
                self.position = SIMD3<Float>( x: position.x + Float(locationTranslation.longitudeTranslation),
                                            y: position.y + Float(locationTranslation.altitudeTranslation),
                                            z: position.z - Float(locationTranslation.latitudeTranslation))
                self.scale = SIMD3<Float>(x: 1, y: 1, z: 1)
            }
        } else {
            //Calculates distance based on the distance within the scene, as the location isn't yet confirmed
            //TODO: This yields zero, perhaps we should investigate
            adjustedDistance = Double(position.distance(to: position))

            scale = SIMD3<Float>(x: 1, y: 1, z: 1)
        }

        return adjustedDistance
    }

    /// See `LocationAnnotationNode`'s override of this function. Because it doesn't invoke `super`'s version, any changes
    /// made in this file must be repeated in `LocationAnnotationNode`.
    func updatePositionAndScale(setup: Bool = false, scenePosition: SIMD3<Float>?, locationNodeLocation nodeLocation: CLLocation,
                                locationManager: SceneLocationARManager, onCompletion: (() -> Void)) {
        guard let position = scenePosition, locationManager.currentLocation != nil else {
            return
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = setup ? 0.0 : 0.1

        let distance = self.location(locationManager.bestLocationEstimate).distance(from:
            locationManager.currentLocation ?? nodeLocation)

        childNodes.first?.renderingOrder = renderingOrder(fromDistance: distance)

        _ = self.adjustedDistance(setup: setup, position: position,
                                  locationNodeLocation: nodeLocation, locationManager: locationManager)

        SCNTransaction.commit()

        onCompletion()
    }

    /// Converts distance from meters to SCNKit rendering order
    /// Constant multiplier eliminates flicker caused by slight distance variations
    /// Nodes with greater rendering orders are rendered last
    func renderingOrder(fromDistance distance: CLLocationDistance) -> Int {
        return Int.max - 1000 - (Int(distance * 1000))
    }
}
