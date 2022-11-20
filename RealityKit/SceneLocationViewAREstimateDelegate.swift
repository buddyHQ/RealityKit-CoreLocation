//
//  SceneLocationViewAREstimateDelegate.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import ARKit
import RealityFoundation
import CoreLocation
import MapKit

// Delegate for touch events on LocationEntity
@available(iOS 13.0, *)
public protocol LNTouchARDelegate: AnyObject {
    func annotationEntityTouched(entity: AnnotationEntity)
    func locationEntityTouched(entity: LocationEntity)
}

@available(iOS 13.0, *)
public protocol SceneLocationARViewEstimateDelegate: AnyObject {
    func didAddSceneLocationEstimate(sceneLocationView: SceneLocationARView, position: SIMD3<Float>, location: CLLocation)
    func didRemoveSceneLocationEstimate(sceneLocationView: SceneLocationARView, position: SIMD3<Float>, location: CLLocation)
}

@available(iOS 13.0, *)
public protocol SceneLocationARViewDelegate: AnyObject {
    ///After a entity's location is initially set based on current location,
    ///it is later confirmed once the user moves far enough away from it.
    ///This update uses location data collected since the entity was placed to give a more accurate location.
    func didConfirmLocationOfEntity(sceneLocationView: SceneLocationARView, entity: LocationEntity)

    func didSetupSceneEntity(sceneLocationView: SceneLocationARView, sceneEntity: Entity)

    func didUpdateLocationAndScaleOfLocationEntity(sceneLocationView: SceneLocationARView, locationEntity: LocationEntity)
}

/// Subset of delegate methods from ARSCNViewDelegate to be notified on tracking status changes
@available(iOS 13.0, *)
public protocol SceneTrackingARDelegate: AnyObject {

    func sessionWasInterrupted(_ session: ARSession)

    func sessionInterruptionEnded(_ session: ARSession)

    func session(_ session: ARSession, didFailWithError error: Error)

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera)

}

@available(iOS 13.0, *)
public extension SceneLocationARViewDelegate {
    func didAddSceneLocationEstimate(sceneLocationARView: SceneLocationARView, position: SIMD3<Float>, location: CLLocation) {
    }
    func didRemoveSceneLocationEstimate(sceneLocationARView: SceneLocationARView, position: SIMD3<Float>, location: CLLocation) {
    }

    func didConfirmLocationOfEntity(sceneLocationARView: SceneLocationARView, entity: LocationEntity) {
    }
    func didSetupSceneEntity(sceneLocationARView: SceneLocationARView, sceneEntity: Entity) {
    }

    func didUpdateLocationAndScaleOfLocationEntity(sceneLocationARView: SceneLocationARView, locationEntity: LocationEntity) {
        //
    }
}
