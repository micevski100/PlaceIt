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
    
    // MARK: - Types
    
    enum MenuState { case opened, closed }
    
    // MARK: - Properties
    
    /// All surface planes that ARKit has detected.
    /// - Used for visualizing detected planes.
    var planes = [UUID : Plane]()
    
    /// All models loaded to the scene.
    var loadedModels = [VirtualObject]()
    
    /// The view controller that displays the object selection menu.
    var modelsMenuController: ModelsMenuController!
    
    /// Holds the model selected from the menu, ready to be placed in the scene.
    /// Set when the user picks a model from the `modelsMenuController`.
    var selectedModelToPlace: String?
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView, controller: self)
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "serialSceneKitQueue")
    
    /// Convenience accessor for the sceneView owned by `MainView`.
    var sceneView: ARSCNView {
        return contentView.sceneView
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return contentView.sceneView.session
    }
    
    /// Current state of the `modelsMenuController`.
    var menuState: MenuState = .closed
    
    /// Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    /// Hide the visual indicator for returning to the Home Screen
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // MARK: - Life Cycle
    
    class func factoryController() -> UINavigationController {
        let controller = MainController()
        let mainController = UINavigationController(rootViewController: controller)
        return mainController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        modelsMenuController = ModelsMenuController()
        modelsMenuController.delegate = self
        
        self.contentView.showModelsMenuButton.addTarget(self, action: #selector(showModelsMenuButtonClick), for: .touchUpInside)
        
        loadHighlightTechnique()
        addTapGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.isLightEstimationEnabled = false
        config.environmentTexturing = .none
        session.run(config)
        
        attachModelsMenuController()
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
}

// MARK: - Actions
extension MainController {
    @objc func showModelsMenuButtonClick() {
        showModelsMenu()
    }
}

// MARK: - Gestures

extension MainController {
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    /// Handles taps on the scene view and performs actions based on context:
    /// 1. Dismisses the menu if it's open.
    /// 2. Places a selected model if one is picked from the menu.
    /// 3. Selects an already placed model for interaction if tapped.
    @objc func didTap(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        if menuState == .opened {
            // Case 1
            if let selectedModelToPlace = selectedModelToPlace {
                guard let raycastQuery = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneGeometry, alignment: .any) else { return }
                guard let raycastResult = session.raycast(raycastQuery).first else { return }
                
                let translation = raycastResult.worldTransform.translation
                addModel(withName: selectedModelToPlace, translation: translation)
                
                self.selectedModelToPlace = nil
            }
            
            // Case 1, 2
            hideModelsMenu()
        } else {
            guard let object = objectInteracting(with: gesture, in: sceneView) else { return }
            
            if (object != virtualObjectInteraction.trackedObject) {
                virtualObjectInteraction.trackedObject?.toggleHighlight()
                object.toggleHighlight()
                
                virtualObjectInteraction.trackedObject = object
            }
        }
    }
    
    /** A helper method to return the first object that is found under the provided `gesture`s touch locations.
     Performs hit tests using the touch locations provided by gesture recognizers. By hit testing against the bounding
     boxes of the virtual objects, this function makes it more likely that a user touch will affect the object even if the
     touch location isn't on a point where the object has visible content. By performing multiple hit tests for multitouch
     gestures, the method makes it more likely that the user touch affects the intended object.
      - Tag: TouchTesting
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

// MARK: - Model Placement

extension MainController {
    func addModel(withName modelName: String, translation: SIMD3<Float>) {
        guard let scene = SCNScene(named: "Models.scnassets/\(modelName).dae") else { return }
        
        let virtualObject = VirtualObject()
        scene.rootNode.childNodes.forEach { virtualObject.addChildNode($0) }
        virtualObject.position = SCNVector3(translation)
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
        loadedModels.append(virtualObject)
    }
}


// MARK: - Model Selection Menu

extension MainController {
    /// Attaches the `modelsMenuController` as a child controller to the `MainController`.
    private func attachModelsMenuController() {
        modelsMenuController.view.frame = CGRect(
            x: self.view.width,
            y: 0,
            width: self.view.width * 0.5,
            height: self.view.height
        )
        addChild(modelsMenuController)
        self.view.addSubview(modelsMenuController.view)
        modelsMenuController.didMove(toParent: self)
    }
    
    /// Shows the `modelsMenuController` when the user taps on the `showObjectsMenuButton`.
    private func showModelsMenu() {
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
}

// MARK: - ARSCNViewDelegate

extension MainController: ARSCNViewDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard planeAnchor.classification == .floor else { return }
        
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        updateQueue.async {
            let plane = Plane(with: planeAnchor)
            self.planes[planeAnchor.identifier] = plane
            node.addChildNode(plane)
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
            if let objectAtAnchor = self.loadedModels.first(where: { $0.anchor == anchor }) {
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

// MARK: - ModelsMenuControllerDelegate

extension MainController: ModelsMenuControllerDelegate {
    func didSelectModel(modelName: String?) {
        selectedModelToPlace = modelName
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MainController: UIGestureRecognizerDelegate {
    // Allow objects to be translated and rotated at the same time.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Highlight Technique

extension MainController {
    /// Loads the technique that is used to achieve a highlight effect around selected `VirtualObject`.
    func loadHighlightTechnique() {
        if let fileUrl = Bundle.main.url(forResource: "RenderOutlineTechnique", withExtension: "plist"), let data = try? Data(contentsOf: fileUrl) {
          if var result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] { // [String: Any] which ever it is
            
            // Update the size and scale factor in the original technique file
            // to whichever size and scale factor the current device is so that
            // we avoid crazy aliasing
            let nativePoints = UIScreen.main.bounds
            let nativeScale = UIScreen.main.nativeScale
            result[keyPath: "targets.MASK.size"] = "\(nativePoints.width)x\(nativePoints.height)"
            result[keyPath: "targets.MASK.scaleFactor"] = nativeScale
            
            guard let technique = SCNTechnique(dictionary: result) else {
              fatalError("This shouldn't be happening.")
            }

            sceneView.technique = technique
          }
        }
        else {
          fatalError("This shouldn't be happening! Technique file has been deleted.")
        }
    }
}
