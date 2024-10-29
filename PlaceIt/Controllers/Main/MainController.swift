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
    var loadedModels = [SCNNode]()
    
    /// Holds the model selected from the menu, ready to be placed in the scene.
    /// Set when the user picks a model from the `modelsMenuController`.
    var selectedModelToPlace: String?
    
    /// Tracks a model already placed in the scene, selected for interaction.
    /// Set when a user taps on a model that is already loaded onto the scene.
    var selectedPlacedModel: SCNNode?
    
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
    
    /// The view controller that displays the object selection menu.
    var modelsMenuController: ModelsMenuController!
    
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
        
        addTapGesture()
        self.contentView.showModelsMenuButton.addTarget(self, action: #selector(showModelsMenuButtonClick), for: .touchUpInside)
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

// MARK: - Gestures

extension MainController {
    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSceneView(withGestureRecognizer:)))
        sceneView.isUserInteractionEnabled = true
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    /// Handles taps on the scene view and performs actions based on context:
    /// 1. Dismisses the menu if it's open.
    /// 2. Places a selected model if one is picked from the menu.
    /// 3. Selects an already placed model for interaction if tapped.
    @objc func didTapSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        if menuState == .opened {
            // Case 1
            if let selectedModelToPlace = selectedModelToPlace {
                let tapLocation = recognizer.location(in: sceneView)
                guard let raycastQuery = sceneView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .any) else { return }
                guard let raycastResult = session.raycast(raycastQuery).first else { return }
                
                let translation = raycastResult.worldTransform.translation
                addModel(withName: selectedModelToPlace, translation: translation)
                
                self.selectedModelToPlace = nil
            }
            
            // Case 1, 2
            hideModelsMenu()
        } else {
            // Case 3
            // TODO: Object Interaction
        }
    }
}

// MARK: - Actions
extension MainController {
    @objc func showModelsMenuButtonClick() {
        showModelsMenu()
    }
}

// MARK: - ARSCNViewDelegate

extension MainController: ARSCNViewDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard planeAnchor.classification == .floor else { return }
        
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = Plane(with: planeAnchor)
        self.planes[planeAnchor.identifier] = plane
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else { return }
        
        // When an anchor is updated we need to also update our 3D geometry too. For example
        // the width and height of the plane detection may have changed so we need to update
        // our SceneKit geometry to match that
        plane.update(with: anchor as! ARPlaneAnchor)
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Nodes will be removed if multiple individual planes that are detected to all be
        // part of a larger plane are merged.
        planes.removeValue(forKey: anchor.identifier)
    }
}

// MARK: - Model Placement

extension MainController {
    func addModel(withName modelName: String, translation: SIMD3<Float>) {
        guard let scene = SCNScene(named: "Models.scnassets/\(modelName).dae") else { return }
        
        let node = SCNNode()
        scene.rootNode.childNodes.forEach { node.addChildNode($0) }
        node.position = SCNVector3(translation)
        node.scale = SCNVector3(0.5, 0.5, 0.5)
        sceneView.scene.rootNode.addChildNode(node)
    }
}


// MARK: - Model Selection Menu

extension MainController {
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

// MARK: - ModelsMenuControllerDelegate
extension MainController: ModelsMenuControllerDelegate {
    func didSelectModel(modelName: String?) {
        selectedModelToPlace = modelName
    }
}
