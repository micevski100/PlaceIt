//
//  MainController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import UIKit
import ARKit
import SceneKit

/// The primary controller of the app. Manages the placement and manipulation of virtual objects
/// within the user's environment, and provides functionality to save the state of the arranged
/// objects for future reference.
class MainController: BaseController<MainView> {
    
    // MARK: - Properties
    
    /// The assoicated virtual room for the current AR session.
    var room: Room!
    
    /// All surface planes that ARKit has detected.
    /// - Used for visualizing detected planes.
    var planes = [UUID : Plane]()
    
    /// Holds the model selected from the menu, ready to be placed in the scene.
    /// Set when the user picks a model from the `modelsMenuController`.
    var selectedModelToPlace: URL? {
        didSet {
            guard selectedModelToPlace != nil else { return }
            self.contentView.tryDisplayTip()
        }
    }
    
    /// Current state of the `modelsMenuController`.
    var menuState: MenuState = .closed
    
    /// The view controller that displays the object selection menu.
    var modelsMenuController: UINavigationController!
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView, controller: self)
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "serialSceneKitQueue")
    
    /// Initial AR session configuration.
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.isLightEstimationEnabled = false
        config.environmentTexturing = .none
        return config
    }
    
    /// Indicates if the mapp is restoring a previous AR session.
    var isRelocalizingMap = false
    
    /// Convenience accessor for the sceneView owned by `MainView`.
    var sceneView: ARView {
        return contentView.sceneView
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return contentView.sceneView.session
    }
    
    /// Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    /// Hide the visual indicator for returning to the Home Screen
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // MARK: - Life Cycle
    
    class func factoryController(_ room: Room) -> BaseController<MainView> {
        let controller = MainController()
        controller.room = room
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        sceneView.delegate = self
        session.delegate = self
        
        
        let bundle = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!
        modelsMenuController = ModelsMenuController.factoryController(dirURL: bundle,
                                                                      isSectionedController: true,
                                                                      delegate: self)
        
        self.contentView.showModelsMenuButton.addTarget(self, action: #selector(showModelsMenuButtonClick), for: .touchUpInside)
        self.contentView.saveExperienceButton.addTarget(self, action: #selector(saveExperienceButtonClick), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        session.run(defaultConfiguration)
        attachModelsMenuController()
        
        // Read in any already saved map to see if we can load one.
        if room.isArchived {
            loadExperience()
        }
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
}

// MARK: - ARSCNViewDelegate

extension MainController: ARSCNViewDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            guard planeAnchor.classification == .floor else { return }
            
            // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
            updateQueue.async {
                let plane = Plane(with: planeAnchor)
                self.planes[planeAnchor.identifier] = plane
                node.addChildNode(plane)
            }
        } else {
            // Save the reference to the VirtualObject's anchor when the anchor is added from relocalizing.
            guard let object = virtualObjectLoader.loadedObjects.first(where: { $0.anchor == anchor }) else { return }
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(object)
            }
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update Plane Geometry to match updated anchor
        DispatchQueue.main.async {
            if let plane = self.planes[anchor.identifier] {
                plane.update(with: anchor as! ARPlaneAnchor)
            }
        }
        
        // Update VirtualObject anchor
        updateQueue.async {
            if let objectAtAnchor = self.virtualObjectLoader.loadedObjects.first(where: { $0.anchor == anchor }) {
                objectAtAnchor.simdPosition = anchor.transform.translation
                objectAtAnchor.anchor = anchor
            }
        }
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Nodes will be removed if multiple individual planes that are detected to all be
        // part of a larger plane are merged.
        planes.removeValue(forKey: anchor.identifier)
    }
}

// MARK: - ARSessionDelegate

extension MainController: ARSessionDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
            break
//            contentView.saveExperienceButton.isHidden = !containingObject(for: frame)
        default:
            break
//            contentView.saveExperienceButton.isHidden = true
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: any Error) {
        contentView.sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap { $0 }.joined(separator: "\n")
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                // TODO: Restart Session
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        contentView.sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        contentView.sessionInfoLabel.text = "Session interruption ended"
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        contentView.snapshotThumbnailImageView.isHidden = true
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped), (.normal, .extending):
            if containingObject(for: frame) {
                // User has placed an object in scene and the session is mapped, prompt them to save the experience
                message = "Tap 'Save Experience' to save the current map."
            } else {
                message = "Tap on the screen to place an object."
            }
            
        case (.normal, _) where !room.isArchived:
            message = "Move around to map the environment."
        
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            contentView.snapshotThumbnailImageView.isHidden = false
        
        default:
            message = trackingState.localizedFeedback
        }
        
        contentView.sessionInfoLabel.text = message
        contentView.sessionInfoView.isHidden = message.isEmpty
    }
    
    private func containingObject(for frame: ARFrame) -> Bool {
        return frame.anchors.contains(where: { anchor in virtualObjectLoader.loadedObjects.contains { $0.anchor == anchor } })
    }
}

// MARK: - AR Persistence

extension MainController {
    @objc func saveExperienceButtonClick() {
        session.getCurrentWorldMap { worlMap, error in
            guard let map = worlMap else {
                self.showAlert(title: "Can't get current world map", message: error!.localizedDescription)
                return
            }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView) else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
            
            do {
                try self.room.setWorldMap(map)
                try self.room.setObjects(self.virtualObjectLoader.loadedObjects)
                try RoomManager.shared.save(room: self.room)
            } catch {
                fatalError("Can't save room: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadExperience() {
        let worldMap: ARWorldMap = {
            do {
                return try self.room.getWorldMap()
            } catch {
                fatalError("Failed to load worldMap: \(error.localizedDescription)")
            }
        }()
        
        let savedModels: [VirtualObject] = {
            do {
                return try self.room.getObjects()
            } catch {
                fatalError("Failed to load savedModels: \(error.localizedDescription)")
            }
        }()
        
        // Display the snapshot image stored in the world map to aid user in relocalizing.
        if let snapshotData = worldMap.snapshotAnchor?.imageData,
           let snapshot = UIImage(data: snapshotData) {
            contentView.snapshotThumbnailImageView.image = snapshot
        } else {
            print("No snapshot image in world map")
        }
        
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll { $0 is SnapshotAnchor }
        
        let configuration = self.defaultConfiguration // The app's standard world tracking settings.
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        isRelocalizingMap = true
        virtualObjectLoader.setLoadedObjects(savedModels)
    }
}

// MARK: - Model Placement and Interaction

extension MainController {
    /// Handles taps on the scene view and performs actions based on the following context:
    /// 1. Dismisses the menu if it's open.
    /// 2. Places a selected model if one is picked from the menu.
    /// 3. Selects an already placed model for interaction if tapped.
    @objc func didTap(_ gesture: UIGestureRecognizer) {
        self.contentView.addModelTip.invalidate(reason: .actionPerformed)
        let touchLocation = gesture.location(in: sceneView)
        
        switch menuState {
        case .opened:
            defer { hideModelsMenu() }
            guard let selectedModelToPlace = selectedModelToPlace else { return }
            guard let raycastQuery = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any) else { return }
            guard let raycastResult = sceneView.session.raycast(raycastQuery).first else { return }
            
            let translation = raycastResult.worldTransform.translation
            let objectPosition = SCNVector3(translation)
            
            self.placeObject(with: selectedModelToPlace, at: objectPosition)
            self.selectedModelToPlace = nil
        case .closed:
            virtualObjectInteraction.trackedObject = objectInteracting(with: gesture, in: sceneView)
            virtualObjectInteraction.didTap(location: touchLocation)
        }
    }
    
    /// Loads the specified `VirtualObject` from the provided URL, and places it  at the given position.
    func placeObject(with url: URL, at position: SCNVector3, completion: @escaping (VirtualObject) -> Void = { _ in }) {
        virtualObjectLoader.loadObject(with: url) { [unowned self] object in
            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene]) { _ in
                    DispatchQueue.main.async {
                        object.position = position
                        self.sceneView.scene.rootNode.addChildNode(object)
                        object.animateScaleUp()
                        
                        self.updateQueue.async {
                            self.sceneView.addOrUpdateAnchor(for: object)
                        }
                        
                        completion(object)
                    }
                }
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }
        }
    }
    
    /** A helper method to return the first object that is found under the provided `gesture`s touch locations.
     Performs hit tests using the touch locations provided by gesture recognizers. By hit testing against the bounding
     boxes of the virtual objects, this function makes it more likely that a user touch will affect the object even if the
     touch location isn't on a point where the object has visible content. By performing multiple hit tests for multitouch
     gestures, the method makes it more likely that the user touch affects the intended object.
    */
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> VirtualObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.virtualObject(at: touchLocation) {
                return object
            }
        }
        
        // As a last resort look for an object under the center of the touches.
        if let center = gesture.center(in: view) {
            return sceneView.virtualObject(at: center)
        }
        
        return nil
    }
}

// MARK: - Models Menu

extension MainController: ModelsMenuControllerDelegate {
    /// Attaches the `modelsMenuController` as a child controller to the `MainController`.
    private func attachModelsMenuController() {
        modelsMenuController.view.frame = CGRect(
            x: self.view.width,
            y: 0,
            width: self.view.width * 0.5,
            height: self.view.height
        )
        addChild(modelsMenuController)
//        self.contentView.addSubview(modelsMenuController.view)
        self.contentView.insertSubview(modelsMenuController.view, belowSubview: self.contentView.sessionInfoView)
        modelsMenuController.didMove(toParent: self)
    }
    
    /// Shows the `modelsMenuController` when the user taps on the `showObjectsMenuButton`.
    @objc func showModelsMenuButtonClick() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        menuState = .opened
        UIView.animate(
            withDuration: 0.5, delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            self.contentView.showModelsMenuButton.alpha = 0
            self.modelsMenuController.view.frame.origin.x -= self.modelsMenuController.view.width
        }
    }
    
    /// Hides the `modelsMenuController` when the user taps on the scene.
    private func hideModelsMenu() {
        self.modelsMenuController.popViewController(animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        menuState = .closed
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            self.contentView.showModelsMenuButton.alpha = 1
            self.modelsMenuController.view.frame.origin.x += self.modelsMenuController.view.width
        }
    }
    
    /// `ModelsMenuControllerDelegate` method for when the user has selected a `VirtualObject` for placement.
    func didSelectModel(modelUrl: URL?) {
        selectedModelToPlace = modelUrl
    }
}
