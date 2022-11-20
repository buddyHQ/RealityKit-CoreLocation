//
//  PolyLineEntity.swift
//  ARCL
//
//  Created by GrandSir on 20.11.2022.
//

import Foundation
import RealityKit
import MapKit

@available(iOS 13.0, *)
public typealias BoxEntityBuilder = (_ distance: CGFloat) -> ModelEntity

/// A Entity that is used to show directions in AR-CL.
@available(iOS 13.0, *)
public class PolylineEntity: LocationEntity {
    public private(set) var locationEntitys = [LocationEntity]()

    public let polyline: MKPolyline
    public let altitude: CLLocationDistance
    public let boxBuilder: BoxEntityBuilder

    /// Creates a `PolylineEntity` from the provided polyline, altitude (which is assumed to be uniform
    /// for all of the points) and an optional SCNBox to use as a prototype for the location boxes.
    ///
    /// - Parameters:
    ///   - polyline: The polyline that we'll be creating location nodes for.
    ///   - altitude: The uniform altitude to use to show the location nodes.
    ///   - tag: a String attribute to identify the node in the scene (e.g when it's touched)
    ///   - boxBuilder: A block that will customize how a box is built.
    public init(polyline: MKPolyline,
                altitude: CLLocationDistance,
                tag: String? = nil,
                boxBuilder: BoxEntityBuilder? = nil) {
        self.polyline = polyline
        self.altitude = altitude
        self.boxBuilder = boxBuilder ?? Constants.defaultBuilder

        super.init(location: nil)

        self.tag = tag ?? Constants.defaultTag

        contructEntitys()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required public init() {
        fatalError("init() has not been implemented")
    }
    
}

// MARK: - Implementation
@available(iOS 13.0, *)
private extension PolylineEntity {

    struct Constants {
        static let defaultBuilder: BoxEntityBuilder = { (distance) -> ModelEntity in
            let color = UIColor(red: 47.0/255.0, green: 125.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            
            let material = SimpleMaterial(color: color, isMetallic: false)
            let box = ModelEntity(mesh: MeshResource.generateBox(width: 1, height: 0.2, depth: Float(distance), cornerRadius: 0, splitFaces: false))
            
            return box
        }
        static let defaultTag: String = ""
    }

    /// This is what actually builds the SCNEntitys and appends them to the
    /// locationEntitys collection so they can be added to the scene and shown
    /// to the user.  If the prototype box is nil, then the default box will be used
    func contructEntitys() {
        let points = polyline.points()

        for i in 0 ..< polyline.pointCount - 1 {
            let currentLocation = CLLocation(coordinate: points[i].coordinate, altitude: altitude)
            let nextLocation = CLLocation(coordinate: points[i + 1].coordinate, altitude: altitude)
            let midLocation = currentLocation.approxMidpoint(to: nextLocation)

            let distance = currentLocation.distance(from: nextLocation)

            let box = boxBuilder(CGFloat(distance))
            let boxEntity = SCNNode(geometry: box)
            boxEntity.removeFlicker()

            let bearing = -currentLocation.bearing(between: nextLocation)

            // Orient the line to point from currentLoction to nextLocation
            boxEntity.eulerAngles.y = Float(bearing).degreesToRadians

            let locationEntity = LocationEntity(location: midLocation, tag: tag)
            locationEntity.addChild(boxEntity)

            locationEntitys.append(locationEntity)
        }
    }

}
