//
//  MainController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import UIKit
import ARKit
import SceneKit

/// The primary controller of the. Manages the placement and manipulation of virtual objects
/// within the user's environment, and provides functionality to save the state of the arranged
/// objects for future reference.
class MainController: BaseController<MainView> {
    
    // MARK: - Properties
    
    /// Used for visualizing detected planes.
    var planes = [UUID : Plane]()
    
    /// Convenience accessor for the sceneView owned by `MainView`.
    var sceneView: ARSCNView {
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
    class func factoryController() -> UINavigationController {
        let controller = MainController()
        let mainController = UINavigationController(rootViewController: controller)
        return mainController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.isLightEstimationEnabled = false
        config.environmentTexturing = .none
        
        session.run(config)
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
