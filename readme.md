![RealityKit + CoreLocation](https://user-images.githubusercontent.com/69051988/202890913-4721003e-827b-4306-a334-f1deb01dd4cb.png)


Note: This fork extends the library [ARKit-CoreLocation](https://github.com/ProjectDent/ARKit-CoreLocation) that is originally written in `SceneKit` to `RealityKit`

<p align="center">
    <a href="https://travis-ci.org/ProjectDent/ARKit-CoreLocation">
        <img src="https://travis-ci.org/ProjectDent/ARKit-CoreLocation.svg?branch=develop" alt="CI Status">
    </a>
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/github/license/ProjectDent/ARKit-CoreLocation.svg"
             alt="MIT License">
    </a>
    <a href="https://cocoapods.org/pods/ARCL">
        <img src="https://img.shields.io/cocoapods/v/ARCL.svg?style=flat"
             alt="Pods Version">
    </a>
    <a href="https://github.com/Carthage/Carthage">
        <img src="https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat"
             alt="Carthage Compatible">
    </a>
</p>

**ARKit**: Uses camera and motion data to map out the local world as you move around.

**CoreLocation**: Uses wifi and GPS data to determine your global location, with a low degree of accuracy.

**ARKit + CoreLocation**: Combines the high accuracy of AR with the scale of GPS data.

![Points of interest demo](https://github.com/ProjectDent/ARKit-CoreLocation/blob/master/giphy-1.gif) ![Navigation demo](https://github.com/ProjectDent/ARKit-CoreLocation/blob/master/giphy-2.gif)

The potential for combining these technologies is huge, with so many potential applications across many different areas. This library comes with two major features:
- Allow items to be placed within the AR world using real-world coordinates.
- Dramatically improved location accuracy, using recent location data points combined with knowledge about movement through the AR world.

The improved location accuracy is currently in an “experimental” phase, but could be the most important component.

Because there’s still work to be done there, and in other areas, this project will best be served by an open community, more than what GitHub Issues would allow us. So I’m opening up a Slack group that anyone can join, to discuss the library, improvements to it, and their own work.

**[Join the Slack community](https://join.slack.com/t/arcl-dev/shared_invite/enQtNTk4OTg4MzU0MTEyLTkyNGZjMDc3NDZlOGZmZTVlNWY1MWYxODg1MTA4ZWMzOThjZDM0ZmY1NGZlZjNiYmE1OGM3MDFkZTNjNjI5ODc)**

## Requirements
ARKit requires iOS 11, and supports the following devices:
- iPhone 6S and upwards
- iPhone SE
- iPad (2017)
- All iPad Pro models

iOS 11 can be downloaded from Apple’s Developer website.

## Usage
This library contains the ARKit + CoreLocation framework, as well as a demo application similar to [Demo 1](https://twitter.com/AndrewProjDent/status/886916872683343872).

[Be sure to read the section on True North calibration.](#true-north-calibration)

### Building with Swift:

```bash
swift build \
        -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" \
        -Xswiftc "-target" -Xswiftc "x86_64-apple-ios12.1-simulator"
```

### Setting up using Swift Package Manager


### Setting up using CocoaPods
1. Add to your podfile:

`pod 'ARCL'`

2. In Terminal, navigate to your project folder, then:

`pod update`

`pod install`

3. Add `NSCameraUsageDescription` and `NSLocationWhenInUseUsageDescription` to plist with a brief explanation (see demo project for an example)

### Setting up manually
1. Add all files from the `ARKit+CoreLocation/Source` directory to your project.
2. Import ARKit, SceneKit, CoreLocation and MapKit.
3. Add `NSCameraUsageDescription` and `NSLocationWhenInUseUsageDescription` to plist with a brief explanation (see demo project for an example)

### Quick start guide
To place a pin over a building, for example Canary Wharf in London, we’ll use the main class that ARCL is built around - `SceneLocationView`.

First, import ARCL and CoreLocation, then declare SceneLocationView as a property:

```swift
import ARCL
import CoreLocation

class ViewController: UIViewController {
  var sceneLocationView = SceneLocationView()
}
```

You should call `sceneLocationView.run()` whenever it’s in focus, and `sceneLocationView.pause()` if it’s interrupted, such as by moving to a different view or by leaving the app.

```swift
override func viewDidLoad() {
  super.viewDidLoad()

  sceneLocationView.run()
  view.addSubview(sceneLocationView)
}

override func viewDidLayoutSubviews() {
  super.viewDidLayoutSubviews()

  sceneLocationView.frame = view.bounds
}
```

After we’ve called `run()`, we can add our coordinate. ARCL comes with a class called `LocationNode` - an object within the 3D scene which has a real-world location along with a few other properties which allow it to be displayed appropriately within the world. `LocationNode` is a subclass of SceneKit’s `SCNNode`, and can also be subclassed further. For this example we’re going to use a subclass called `LocationAnnotationNode`, which we use to display a 2D image within the world, which always faces us:

```swift
let coordinate = CLLocationCoordinate2D(latitude: 51.504571, longitude: -0.019717)
let location = CLLocation(coordinate: coordinate, altitude: 300)
let image = UIImage(named: "pin")!

let annotationNode = LocationAnnotationNode(location: location, image: image)
```

`LocationAnnotationNode` can also be initialized using a UIView. Internally, the UIView is converted into UIImage, so you cannot update the content dynamically.
However, this methods allows you to easily show complex layout as POI.

```swift
let coordinate = CLLocationCoordinate2D(latitude: 51.504571, longitude: -0.019717)
let location = CLLocation(coordinate: coordinate, altitude: 300)
let view = UIView() // or a custom UIView subclass

let annotationNode = LocationAnnotationNode(location: location, view: view)
```

It can also be initialized with CALayer. You can use this when you want to update the contents live.

```swift
let coordinate = CLLocationCoordinate2D(latitude: 51.504571, longitude: -0.019717)
let location = CLLocation(coordinate: coordinate, altitude: 300)
let layer = CALayer() // or a custom CALayer subclass

let annotationNode = LocationAnnotationNode(location: location, layer: layer)
```

By default, the image you set should always appear at the size it was given, for example if you give a 100x100 image, it would appear at 100x100 on the screen. This means distant annotation nodes can always be seen at the same size as nearby ones. If you’d rather they scale relative to their distance, you can set LocationAnnotationNode’s `scaleRelativeToDistance` to `true`.

```swift
sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
```

There are two ways to add a location node to a scene - using `addLocationNodeWithConfirmedLocation`, or `addLocationNodeForCurrentPosition`, which positions it to be in the same position as the device, within the world, and then gives it a coordinate.

So that’s it. If you set the frame of your sceneLocationView, you should now see the pin hovering above Canary Wharf.

In order to get a notification when a node is touched in the `sceneLocationView`, you need to conform to `LNTouchDelegate` in the ViewController class. 

The `annotationNodeTouched(node: AnnotationNode)` gives you access to node that was touched on the screen. `AnnotationNode` is a subclass of SCNNode with two extra properties: `image: UIImage?` and `view: UIView?`. Either of these properties will be filled in based on how the `LocationAnnotationNode` was initialized (using the constructor that takes UIImage or UIView).

The `locationNodeTouched(node: LocationNode)` gives you instead access to the nodes created from a `PolyNode` (e.g. the rendered directions of a `MKRoute`).
```swift
class ViewController: UIViewController, LNTouchDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        //...
        self.sceneLocationView.locationNodeTouchDelegate = self
        //...
    }

    func annotationNodeTouched(node: AnnotationNode) {
        // Do stuffs with the node instance

        // node could have either node.view or node.image
        if let nodeView = node.view{
            // Do stuffs with the nodeView
            // ...
        }
        if let nodeImage = node.image{
            // Do stuffs with the nodeImage
            // ...
        }
    }

    func locationNodeTouched(node: LocationNode) {
        guard let name = node.tag else { return }
        guard let selectedNode = node.childNodes.first(where: { $0.geometry is SCNBox }) else { return }

        // Interact with the selected node
    }

}
```
## Additional features
The library and demo come with a bunch of additional features for configuration. It’s all fully documented to be sure to have a look around.

SceneLocationView is a subclass of ARSCNView. Note that while this gives you full access to ARSCNView to use it in other ways, you should not set the delegate to another class. If you need to use delegate features then you should subclass `SceneLocationView`.

## True North calibration
One issue which I haven’t personally been able to overcome is that the iPhone’s True North calibration currently has an accuracy of 15º at best. This is fine for maps navigation, but when placing things on top of the AR world, it starts to become a problem.

I’m confident that this issue can be overcome by using various AR techniques - it’s one area I think can really benefit from a shared effort.

To improve this currently, I’ve added some functions to the library that allow adjusting the north point:
- `sceneLocationView.moveSceneHeadingClockwise`
- `sceneLocationView.moveSceneHeadingAntiClockwise`
- `sceneLocationView.resetSceneHeading`

You should use these by setting `sceneLocationView.useTrueNorth` to `false`, and then pointing the device in the general direction of north before beginning, so it’s reasonably close. With `useTrueNorth` set to true (default), it would continually adjust as it gets a better sense of north.

Within the demo app, there’s a disabled property called `adjustNorthByTappingSidesOfScreen`, which accesses these functions, and, once enabled, allows tapping on the left and right of the screen to adjust the scene heading.

My recommendation would be to fine a nearby landmark which is directly True North from your location, place an object there using a coordinate, and then use the `moveSceneHeading` functions to adjust the scene until it lines up.

## Improved Location Accuracy
CoreLocation can deliver location updates anywhere from every 1-15 seconds, with accuracies which vary from 150m down to 4m. Occasionally, you’ll receive a far more accurate reading, like 4m or 8m, before returning to more inaccurate readings. At the same time, AR uses motion and camera data to create a map of the local world.

A user may receive a location reading accurate to 4m, then they walk 10m north and receive another location reading accurate to 65m. This 65m-accurate reading is the best that CoreLocation can offer, but knowing the user’s position within the AR scene when they got that 4m reading, and the fact that they’ve walked 10m north through the scene since then, we can translate that data to give them a new coordinate with about 4m of accuracy. This is accurate up to about 100m.

[There is more detail on this on the wiki](https://github.com/ProjectDent/ARKit-CoreLocation/wiki/Current-Location-Accuracy).

### Issues
I mentioned this was experimental - currently, ARKit occasionally gets confused as the user is walking through a scene, and may change their position inaccurately. This issue also seems to affect the “euler angles”, or directional information about the device, so after a short distance it may think you’re walking in a different direction.

While Apple can improve ARKit over time, I think there are improvements we can make to avoid those issues, such as recognising when it happens and working to correct it, and by comparing location data with our supposed location to determine if we’ve moved outside a possible bounds.

### Location Algorithm Improvements
There are further optimisations to determining a user’s location which can be made.

For example, one technique could be to look at recent location data, translate each data point using the user’s travel since then, and use the overlap between the data points to more narrowly determine the user’s possible location.

[There is more detail on this on the wiki](https://github.com/ProjectDent/ARKit-CoreLocation/wiki/Current-Location-Accuracy).

## Going Forward

We have some Milestones and Issues related to them - anyone is welcome to discuss and contribute to them. Pull requests are welcomed. You can discuss new features/enhancements/bugs either by adding a new Issue or via [the Slack community](https://join.slack.com/t/arcl-dev/shared_invite/enQtNTk4OTg4MzU0MTEyLTkyNGZjMDc3NDZlOGZmZTVlNWY1MWYxODg1MTA4ZWMzOThjZDM0ZmY1NGZlZjNiYmE1OGM3MDFkZTNjNjI5ODc).

## Help / Examples
- [360 iDev 2019: Eric Internicola - Build immersive experiences with ARKit and CoreLocation](https://vimeo.com/361883047)
    - What if you could create objects and set a real-world (fixed) location for them and view those objects using ARKit? A library called ARCL combines the power of CoreLocation with ARKit and lets you do just that! Allow users to use their device to look in the direction of a landmark. Allow users to see location-bound objects on their device using AR. Show you users directions as they walk the streets!
- [360iDevARNavigation - Reference Navigation App](https://github.com/intere/360iDevARNavigation)
    -  Draws blue lines on the road for navigation (similar to the demo video at the top of this README)
- [GeoTrackKit - ARCL Integration](https://github.com/intere/GeoTrackKit/pull/19)
    - Integrates ARCL with a tracking library `GeoTrackKit` and has some useful demo screencasts

## Thanks
Library created by [@AndrewProjDent](https://twitter.com/andrewprojdent), but a community effort from here on.

Available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
