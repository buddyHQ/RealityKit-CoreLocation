//
//  LocationAnnotationEntity.swift
//  Pods
//
//  Created by GrandSir on 21.11.2022.
//

import Foundation
import SceneKit
import CoreLocation
import RealityFoundation

/// A `LocationNode` which has an attached `AnnotationNode`.
@available(iOS 13.0, *)
open class LocationAnnotationEntity: LocationEntity {
    /// Subnodes and adjustments should be applied to this subnode
    /// Required to allow scaling at the same time as having a 2D 'billboard' appearance
    public let annotationEntity: AnnotationEntity
    /// Parameter to raise or lower the label's rendering position relative to the node's actual project location.
    /// The default value of 1.1 places the label at a pleasing height above the node.
    /// To draw the label exactly on the true location, use a value of 0. To draw it below the true location,
    /// use a negative value.
    public var annotationHeightAdjustmentFactor = 1.1

    public init(location: CLLocation?, image: UIImage) {
        let mesh = MeshResource.generatePlane(width: Float(image.size.width) / 100, height: Float(image.size.height / 100))
        
        var material = SimpleMaterial()
        
        if #available(iOS 15.0, *) {
            material.color = .init(tint: .white.withAlphaComponent(0.999),
                                texture: .init(try! .load(named: "texture.png")))
        }
        else {
            material.baseColor = try! .texture(.load(named: "buddy"))
            material.tintColor = UIColor.white
        }

        annotationEntity = AnnotationEntity(view: nil, image: image, mesh: mesh)
        annotationEntity.geometry = plane
        annotationEntity.removeFlicker()

        super.init(location: location)

        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]

        addChild(annotationEntity)
    }

    /// Use this constructor to add a UIView as an annotation.  Keep in mind that it is not live, instead
    /// it's a "snapshot" of that UIView.  UIView is more configurable then a UIImage, allowing you to add
    /// background image, labels, etc.
    ///
    /// - Parameters:
    ///   - location:The location of the node in the world.
    ///   - view:The view to display at the specified location.
    public convenience init(location: CLLocation?, view: UIView) {
        self.init(location: location, image: view.image)
    }

    public init(location: CLLocation?, layer: CALayer) {
        let plane = SCNPlane(width: layer.bounds.size.width / 100, height: layer.bounds.size.height / 100)
        plane.firstMaterial?.diffuse.contents = layer
        plane.firstMaterial?.lightingModel = .constant

        annotationEntity = AnnotationEntity(view: nil, image: nil, layer: layer)
        annotationEntity.geometry = plane
        annotationEntity.removeFlicker()

        super.init(location: location)

        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]

        addChild(annotationEntity)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Note: we repeat code from `LocationNode`'s implementation of this function. Is this because of the use of `SCNTransaction`
    /// to wrap the changes? It's legal to nest the calls, should consider this if any more changes to
    /// `LocationNode`'s implementation are needed.
    override func updatePositionAndScale(setup: Bool = false, scenePosition: SIMD3<Float>?,
                                         locationEntityLocation entityLocation: CLLocation,
                                         locationManager: SceneLocationARManager,
                                         onCompletion: (() -> Void)) {
        guard let position = scenePosition, let location = locationManager.currentLocation else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = setup ? 0.0 : 0.1

        let distance = self.location(locationManager.bestLocationEstimate).distance(from: location)

        childNodes.first?.renderingOrder = renderingOrder(fromDistance: distance)

        let adjustedDistance = self.adjustedDistance(setup: setup, position: position,
                                                     locationEntityLocation: entityLocation, locationManager: locationManager)

        // The scale of a node with a billboard constraint applied is ignored
        // The annotation subnode itself, as a subnode, has the scale applied to it
        let appliedScale = self.scale
        self.scale = SIMD3<Float>(x: 1, y: 1, z: 1)

        var scale: Float

        if scaleRelativeToDistance {
            scale = appliedScale.y
            annotationEntity.scale = appliedScale
            annotationEntity.children.forEach { child in
                child.scale = appliedScale
            }
        } else {
            let scaleFunc = scalingScheme.getScheme()
            scale = scaleFunc(distance, adjustedDistance)

            annotationEntity.scale = SIMD3<Float>(x: scale, y: scale, z: scale)
            annotationEntity.children.forEach { node in
                node.scale = SIMD3<Float>(x: scale, y: scale, z: scale)
            }
        }

        // Translate the pivot's Y coordinate so the label will show above or below the actual node location.
        let transform = Transform(pitch: 0, yaw: Float(-1 * annotationHeightAdjustmentFactor) * scale, roll: 0)
        self.move(to: transform, relativeTo: annotationEntity)

        SCNTransaction.commit()

        onCompletion()
    }
}
