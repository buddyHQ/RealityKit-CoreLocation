//
//  SceneLocationARView.swift
//  ARCL
//
//  Created by GrandSir on 19.11.2022.
//

import Foundation
import ARKit
import CoreLocation
import MapKit
import SwiftUI
import RealityKit


//Should conform to delegate here, add in future commit
@available(iOS 13.0, *)

/// `SceneLocationARView` is the `ARSCNView` subclass used to render an ARCL scene.
///
/// Note that all of the standard SceneKit/ARKit delegates and delegate methods are used
/// internally by ARCL. The delegate functions declared in `ARSCNViewDelegate`, `ARSessionObserver`, and  `ARSCNView` are
/// shadowed by `ARSCNViewDelegate` and invoked on the `SceneLocationARView`'s `arDelegate`. If you need to receive
/// any of these callbacks, implement them on your `arDelegate`.
open class SceneLocationARView: ARView {
    /// The limit to the scene, in terms of what data is considered reasonably accurate.
    /// Measured in meters.
    static let sceneLimit = 100.0
    
    /// The type of tracking to use.
    ///
    /// - orientationTracking: Informs the `SceneLocationARView` to use Device Orientation tracking only.
    ///  Useful when your nodes are all CLLocation based, and are not synced to real world planes
    ///  See [Apple's documentation](https://developer.apple.com/documentation/arkit/arorientationtrackingconfiguration)
    /// - worldTracking: Informs the `SceneLocationARView` to use a World Tracking Configuration.
    ///  Useful when you have nodes that attach themselves to real world planes
    ///  See [Apple's documentation](https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration#overview)
    public enum ARTrackingType {
        case orientationTracking
        case worldTracking
    }
    
    public weak var locationViewDelegate: SceneLocationARViewDelegate?
    public weak var locationEstimateDelegate: SceneLocationARViewEstimateDelegate?
    public weak var locationEntityTouchDelegate: LNTouchARDelegate?
    public weak var sceneTrackingDelegate: SceneTrackingARDelegate?
    
    internal var pointOfView : SIMD3<Float> {
        let perspectiveCamera = PerspectiveCamera()
        let position = perspectiveCamera.position
        
        return position
    }
    
    public let sceneLocationManager = SceneLocationARManager()
    
    /// Addresses [Issue #196](https://github.com/ProjectDent/ARKit-CoreLocation/issues/196) -
    /// Delegate issue when assigned to self (no location nodes render).   If the user
    /// tries to set the delegate, perform an assertionFailure and tell them to set the `arViewDelegate` instead.
    open var delegate: ARSessionDelegate?
    open var arSessionDelegate : ARSessionDelegate?
    
    /// The method to use for determining locations.
    /// Not advisable to change this as the scene is ongoing.
    public var locationEstimateMethod: LocationEstimateMethod {
        get {
            return sceneLocationManager.locationEstimateMethod
        }
        set {
            sceneLocationManager.locationEstimateMethod = newValue
            
            locationEntities.forEach { $0.locationEstimateMethod = newValue }
        }
    }
    
    /// When set to true, displays an axes entity at the start of the scene
    public var showAxesNode = false
    
    public internal(set) var sceneEntity: AnchorEntity? {
        didSet {
            guard sceneEntity != nil else { return }
            
            locationEntities.forEach { sceneEntity?.addChild($0) }
            
            locationViewDelegate?.didSetupSceneEntity(sceneLocationARView: self, sceneEntity: sceneEntity!)
        }
    }
    
    /// Only to be overrided if you plan on manually setting True North.
    /// When true, sets up the scene to face what the device considers to be True North.
    /// This can be inaccurate, hence the option to override it.
    /// The functions for altering True North can be used irrespective of this value,
    /// but if the scene is oriented to true north, it will update without warning,
    /// thus affecting your alterations.
    /// The initial value of this property is respected.
    public var orientToTrueNorth = true
    
    /// Whether debugging feature points should be displayed.
    /// Defaults to false
    public var showFeaturePoints = false
    
    // MARK: Scene location estimates
    public var currentScenePosition: SIMD3<Float>? {
        let perspectiveCamera = PerspectiveCamera()
        let position = perspectiveCamera.position
        let pos = sceneEntity?.convert(position: position, to: nil)
        
        return pos
    }
    
    public var currentEulerAngles: SIMD3<Float>? {
        return self.session.currentFrame?.camera.eulerAngles
        
    }
    
    public internal(set) var locationEntities = [LocationEntity]()
    public internal(set) var polylineEntities = [PolylineEntity]()
    public internal(set) var arTrackingType: ARTrackingType = .worldTracking
    
    // MARK: Internal desclarations
    internal var didFetchInitialLocation = false
    
    // MARK: Setup
    
    /// This initializer allows you to specify the type of tracking configuration (defaults to world tracking) as well as
    /// some other optional values.
    ///
    /// - Parameters:
    ///   - trackingType: The type of AR Tracking configuration (defaults to world tracking).
    ///   - frame: The CGRect for the frame (defaults to .zero).
    ///   - options: The rendering options for the `SCNView`.
    public convenience init(trackingType: ARTrackingType = .worldTracking, frame: CGRect = .zero, options: [String: Any]? = nil) {
        self.init(frame: frame)
        self.arTrackingType = trackingType
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        finishInitialization()
    }
    
    @MainActor public required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")

    }
    
    // https://stackoverflow.com/questions/58355898/how-to-set-entity-in-front-of-screen-with-reality-kit
    private func finishInitialization() {
        sceneLocationManager.sceneLocationDelegate = self
        
        delegate = self
        
        // MARK: Unknown attribute
        //debugOptions = showFeaturePoints ? [ARSCNDebugOptions.showFeaturePoints] : debugOptions
        
        let touchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sceneLocationViewTouched(sender:)))
        self.addGestureRecognizer(touchGestureRecognizer)
    }
    
    /// Resets the scene heading to 0
    func resetSceneHeading() {
        self.sceneEntity?.position.y = .zero
    }
    
    func confirmLocationOfLocationEntity(_ locationEntity: LocationEntity) {
        locationEntity.location = locationOfLocationEntity(locationEntity)
        locationViewDelegate?.didConfirmLocationOfEntity(sceneLocationView: self, entity: locationEntity)
    }
    
    /// Gives the best estimate of the location of a entity
    public func locationOfLocationEntity(_ locationEntity: LocationEntity) -> CLLocation {
        if locationEntity.locationConfirmed || locationEstimateMethod == .coreLocationDataOnly {
            return locationEntity.location!
        }
        
        if let bestLocationEstimate = sceneLocationManager.bestLocationEstimate,
           locationEntity.location == nil
            || bestLocationEstimate.location.horizontalAccuracy < locationEntity.location!.horizontalAccuracy {
            return bestLocationEstimate.translatedLocation(to: locationEntity.position)
        } else {
            return locationEntity.location!
        }
    }
}

@available(iOS 13.0, *)
public extension SceneLocationARView {
    func run() {
        switch arTrackingType {
        case .worldTracking:
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.worldAlignment = orientToTrueNorth ? .gravityAndHeading : .gravity
            session.run(configuration, options: [.resetTracking,.removeExistingAnchors,.stopTrackedRaycasts])
            
        case .orientationTracking:
            let configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = orientToTrueNorth ? .gravityAndHeading : .gravity
            session.run(configuration, options: [.resetTracking,.removeExistingAnchors,.stopTrackedRaycasts])
        }
        sceneLocationManager.run()
    }
    
    func pause() {
        session.pause()
        sceneLocationManager.pause()
    }
    
    // MARK: True North
    
    /// iOS can be inaccurate when setting true north
    /// The scene is oriented to true north, and will update its heading when it gets a more accurate reading
    /// You can disable this through setting the
    /// These functions provide manual overriding of the scene heading,
    /// if you have a more precise idea of where True North is
    /// The goal is for the True North orientation problems to be resolved
    /// At which point these functions would no longer be useful
    /// Moves the scene heading clockwise by 1 degree
    /// Intended for correctional purposes
    func moveSceneHeadingClockwise() {
        sceneEntity?.transform.translation.y -= Float(1).degreesToRadians
    }
    
    /// Moves the scene heading anti-clockwise by 1 degree
    /// Intended for correctional purposes
    func moveSceneHeadingAntiClockwise() {
        sceneEntity?.transform.translation.y -= Float(1).degreesToRadians
    }
    
    // MARK: LocationEntitys
    
    /// Upon being added, a entity's location, locationConfirmed and position may be modified and should not be changed externally.
    /// Silently fails and returns without adding the entity to the scene if any of `currentScenePosition`,
    /// `sceneLocationManager.currentLocation`, or `sceneNode` is `nil`.
    func addLocationEntityForCurrentPosition(locationEntity: LocationEntity) {
        guard let currentPosition = currentScenePosition,
              let currentLocation = sceneLocationManager.currentLocation,
              let sceneEntity = sceneEntity else { return }
        
        locationEntity.location = currentLocation
        locationEntity.position = currentPosition
        
        locationEntities.append(locationEntity)
        sceneEntity.addChild(locationEntity)
    }
    
    /// Each entity's addition to the scene can silently fail; See `addLocationEntityForCurrentPosition(locationEntity:)`.
    ///
    /// Why would we want to add multiple nodes at the current position?
    func addLocationEntitysForCurrentPosition(locationEntities: [LocationEntity]) {
        locationEntities.forEach { addLocationEntityForCurrentPosition(locationEntity: $0) }
    }
    
    /// Silently fails and returns without adding the entity unless`location` is not `nil` and `locationConfirmed` is `true`.
    /// Upon being added, a entity's position will be modified internally and should not be changed externally.
    /// `location` will not be modified, but taken as accurate.
    func addLocationEntityWithConfirmedLocation(locationEntity: LocationEntity) {
        if locationEntity.location == nil || locationEntity.locationConfirmed == false {
            return
        }
        
        let locationEntityLocation = locationOfLocationEntity(locationEntity)
        
        locationEntity.updatePositionAndScale(setup: true,
                                              scenePosition: currentScenePosition, locationEntityLocation: locationEntityLocation,
                                            locationManager: sceneLocationManager) {
            self.locationViewDelegate?
                .didUpdateLocationAndScaleOfLocationEntity(sceneLocationARView: self,
                                                           locationEntity: locationEntity)
        }
        
        locationEntities.append(locationEntity)
        sceneEntity?.addChild(locationEntity)
    }
    
    @objc func sceneLocationViewTouched(sender: UITapGestureRecognizer) {
        guard let touchedView = sender.view as? ARView else {
            print("DEBUG: Error when initalizing ARView")
            return
        }
        
        let coordinates = sender.location(in: touchedView)
        let hitTests = touchedView.hitTest(coordinates)
        
        guard let firstHitTest = hitTests.first else {
            return
        }
        
        if let touchedEntity = firstHitTest.entity as? AnnotationEntity {
            self.locationEntityTouchDelegate?.annotationEntityTouched(entity: touchedEntity)
        } else if let locationEntity = firstHitTest.entity.parent as? LocationEntity {
            self.locationEntityTouchDelegate?.locationEntityTouched(entity: locationEntity)
        }
    }
    
    /// Each entity's addition to the scene can silently fail; See `addLocationEntityWithConfirmedLocation(locationEntity:)`.
    func addLocationEntitysWithConfirmedLocation(locationEntities: [LocationEntity]) {
        locationEntities.forEach { addLocationEntityWithConfirmedLocation(locationEntity: $0) }
    }
    
    func removeAllNodes() {
        locationEntities.removeAll()
        guard let children = sceneEntity?.children else { return }
        for entity in children {
            entity.removeFromParent()
        }
    }
    
    /// Determine if scene contains a entity with the specified tag
    ///
    /// - Parameter tag: tag text
    /// - Returns: true if a LocationEntity with the tag exists; false otherwise
    func sceneContainsNodeWithTag(_ tag: String) -> Bool {
        return findNodes(tagged: tag).count > 0
    }
    
    /// Find all location nodes in the scene tagged with `tag`
    ///
    /// - Parameter tag: The tag text for which to search nodes.
    /// - Returns: A list of all matching tags
    func findNodes(tagged tag: String) -> [LocationEntity] {
        guard tag.count > 0 else {
            return []
        }
        
        return locationEntities.filter { $0.tag == tag }
    }
    
    func removeLocationEntity(locationEntity: LocationEntity) {
        if let index = locationEntities.firstIndex(of: locationEntity) {
            locationEntities.remove(at: index)
        }
        
        locationEntity.removeFromParent()
    }
    
    func removeLocationEntitys(locationEntities: [LocationEntity]) {
        locationEntities.forEach { removeLocationEntity(locationEntity: $0) }
    }
}

@available(iOS 13.0, *)
public extension SceneLocationARView {
    
    /// Adds routes to the scene and lets you specify the geometry prototype for the box.
    /// Note: You can provide your own SCNBox prototype to base the direction nodes from.
    ///
    /// - Parameters:
    ///   - routes: The MKRoute of directions
    ///   - boxBuilder: A block that will customize how a box is built.
    func addRoutes(routes: [MKRoute], boxBuilder: BoxEntityBuilder? = nil) {
        addRoutes(polylines: routes.map { AttributedType(type: $0.polyline,
                                                         attribute: $0.name) },
                  boxBuilder: boxBuilder)
    }
    
    /// Adds polylines to the scene and lets you specify the geometry prototype for the box.
    /// Note: You can provide your own SCNBox prototype to base the direction nodes from.
    ///
    /// - Parameters:
    ///   - polylines: The list of attributed MKPolyline to rendered
    ///   - Δaltitude: difference between box and current user altitude
    ///   - boxBuilder: A block that will customize how a box is built.
    func addRoutes(polylines: [AttributedType<MKPolyline>],
                   Δaltitude: CLLocationDistance = -2.0,
                   boxBuilder: BoxEntityBuilder? = nil) {
        guard let altitude = sceneLocationManager.currentLocation?.altitude else {
            return assertionFailure("we don't have an elevation")
        }
        let polyEntities = polylines.map {
            PolylineEntity(polyline: $0.type,
                         altitude: altitude + Δaltitude,
                         tag: $0.attribute,
                         boxBuilder: boxBuilder)
        }
        
        polylineEntities.append(contentsOf: polyEntities)
        polyEntities.forEach {
            $0.locationEntities.forEach {
                let locationEntityLocation = self.locationOfLocationEntity($0)
                $0.updatePositionAndScale(setup: true,
                                          scenePosition: currentScenePosition,
                                          locationEntityLocation: locationEntityLocation,
                                          locationManager: sceneLocationManager,
                                          onCompletion: {})
                sceneEntity?.addChild($0)
            }
        }
    }
    
    func removeRoutes(routes: [MKRoute]) {
        routes.forEach { route in
            if let index = polylineEntities.firstIndex(where: { $0.polyline == route.polyline }) {
                polylineEntities.remove(at: index)
            }
        }
    }
}

@available(iOS 13.0, *)
public extension SceneLocationARView {
    /// Adds polylines to the scene and lets you specify the geometry prototype for the box.
    /// Note: You can provide your own SCNBox prototype to base the direction nodes from.
    ///
    /// - Parameters:
    ///   - polylines: A set of MKPolyline.
    ///   - boxBuilder: A block that will customize how a box is built.
    func addPolylines(polylines: [MKPolyline], boxBuilder: BoxEntityBuilder? = nil) {
        
        guard let altitude = sceneLocationManager.currentLocation?.altitude else {
            return assertionFailure("we don't have an elevation")
        }
        polylines.forEach { (polyline) in
            polylineEntities.append(PolylineEntity(polyline: polyline, altitude: altitude - 2.0, boxBuilder: boxBuilder))
        }
        
        polylineEntities.forEach {
            $0.locationEntities.forEach {
                
                let locationEntityLocation = self.locationOfLocationEntity($0)
                $0.updatePositionAndScale(setup: true,
                                          scenePosition: currentScenePosition,
                                          locationEntityLocation: locationEntityLocation,
                                          locationManager: sceneLocationManager,
                                          onCompletion: {})
                
                sceneEntity?.addChild($0)
            }
        }
    }
    
    func removePolylines(polylines: [MKPolyline]) {
        polylines.forEach { polyline in
            if let index = polylineEntities.firstIndex(where: { $0.polyline == polyline }) {
                polylineEntities.remove(at: index)
            }
        }
    }
}

@available(iOS 13.0, *)
extension SceneLocationARView: SceneLocationARManagerDelegate {
    var scenePosition: SIMD3<Float>? { return currentScenePosition }
    
    func confirmLocationOfDistantLocationEntitys() {
        guard let currentPosition = currentScenePosition else { return }
        
        locationEntities.filter { !$0.locationConfirmed }.forEach {
            let currentPoint = CGPoint.pointWithVector(vector: currentPosition)
            let locationEntityPoint = CGPoint.pointWithVector(vector: $0.position)
            
            if !currentPoint.radiusContainsPoint(radius: CGFloat(SceneLocationARView.sceneLimit), point: locationEntityPoint) {
                confirmLocationOfLocationEntity($0)
            }
        }
    }
    
    /// Updates the position and scale of the `polylineEntities` and the `locationEntities`.
    func updatePositionAndScaleOfLocationEntitys() {
        polylineEntities.filter { $0.continuallyUpdatePositionAndScale }.forEach { entity in
            entity.locationEntities.forEach { entity in
                let locationEntityLocation = self.locationOfLocationEntity(entity)
                entity.updatePositionAndScale(
                    setup: false,
                    scenePosition: currentScenePosition,
                    locationEntityLocation: locationEntityLocation,
                    locationManager: sceneLocationManager) {
                        self.locationViewDelegate?.didUpdateLocationAndScaleOfLocationEntity(
                            sceneLocationView: self, locationEntity: entity)
                    } // updatePositionAndScale
            } // foreach Location entity
        } // foreach Polyline entity
        
        locationEntities.filter { $0.continuallyUpdatePositionAndScale }.forEach { entity in
            let locationEntityLocation = locationOfLocationEntity(entity)
            entity.updatePositionAndScale(
                scenePosition: currentScenePosition,
                locationEntityLocation: locationEntityLocation,
                locationManager: sceneLocationManager) {
                    self.locationViewDelegate?.didUpdateLocationAndScaleOfLocationEntity(
                        sceneLocationView: self, locationEntity: entity)
                }
        }
    }
    
    func didAddSceneLocationEstimate(position: SIMD3<Float>, location: CLLocation) {
        locationEstimateDelegate?.didAddSceneLocationEstimate(sceneLocationView: self, position: position, location: location)
    }
    
    func didRemoveSceneLocationEstimate(position: SIMD3<Float>, location: CLLocation) {
        locationEstimateDelegate?.didRemoveSceneLocationEstimate(sceneLocationView: self, position: position, location: location)
    }
}
