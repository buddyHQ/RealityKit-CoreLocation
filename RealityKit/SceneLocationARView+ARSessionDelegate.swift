//
//  SceneLocationARView+ARSessionDelegate.swift
//  ARCL
//
//  Created by GrandSir on 20.11.2022.
//

import RealityFoundation
import ARKit

@available(iOS 13.0, *)
extension SceneLocationARView : ARSessionDelegate {
   
    public func session(_ session: ARSession, didFailWithError error: Error) {
        defer {
            arSessionDelegate?.session?(session, didFailWithError: error)
        }
        print("session did fail with error: \(error)")
        sceneTrackingDelegate?.session(session, didFailWithError: error)
    }

    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(.insufficientFeatures):
            print("camera did change tracking state: limited, insufficient features")
        case .limited(.excessiveMotion):
            print("camera did change tracking state: limited, excessive motion")
        case .limited(.initializing):
            print("camera did change tracking state: limited, initializing")
        case .normal:
            print("camera did change tracking state: normal")
        case .notAvailable:
            print("camera did change tracking state: not available")
        case .limited(.relocalizing):
            print("camera did change tracking state: limited, relocalizing")
        default:
            print("camera did change tracking state: unknown...")
        }
        sceneTrackingDelegate?.session(session, cameraDidChangeTrackingState: camera)
    }

    public func sessionWasInterrupted(_ session: ARSession) {
        defer {
            arSessionDelegate?.sessionWasInterrupted?(session)
        }
        print("session was interrupted")
        sceneTrackingDelegate?.sessionWasInterrupted(session)
    }

    public func sessionInterruptionEnded(_ session: ARSession) {
        defer {
            arSessionDelegate?.sessionInterruptionEnded?(session)
        }
        print("session interruption ended")
        sceneTrackingDelegate?.sessionInterruptionEnded(session)
    }

    public func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return arSessionDelegate?.sessionShouldAttemptRelocalization?(session) ?? true
    }

    public func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        arSessionDelegate?.session?(session, didOutputAudioSampleBuffer: audioSampleBuffer)
    }
}
