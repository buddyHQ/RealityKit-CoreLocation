//
//  POIViewController+ARSCNViewDelegate.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 6/23/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import ARKit
import UIKit

@available(iOS 11.0, *)
extension POIViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("Added SCNNode: \(node)")    // you probably won't see this fire
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        print("willUpdate: \(node)")    // you probably won't see this fire
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("Camera: \(camera)")
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
        switch error._code {
        case 102:
            self.sceneLocationView.session.configuration!.worldAlignment = .gravity
            restartSessionWithoutDelete()
        default:
            self.sceneLocationView.session.configuration!.worldAlignment = .gravityAndHeading
            restartSessionWithoutDelete()
        }
        self.sceneLocationView.session(session, didFailWithError: error)
    }
    
    @objc func restartSessionWithoutDelete() {
        // Restart session with a different worldAlignment - prevents bug from crashing app
        self.sceneLocationView.session.pause()

        self.sceneLocationView.session.run(self.sceneLocationView.session.configuration!, options: [
            .resetTracking,
            .removeExistingAnchors
        ])
    }
    
    
}
