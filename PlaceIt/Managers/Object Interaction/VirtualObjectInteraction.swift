//
//  VirtualObjectInteraction.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 2.11.24.
//

import UIKit
import ARKit

/// Manages user interaction with virtual objects to enable one-finger tap, one and two-finger pan, and
/// two finger rotation gesture recognizers to let the user position and orient virtual objects.
class VirtualObjectInteraction: NSObject {
    
    // MARK: - Properties
    
    /// The scene view to hit test against when moving virtual content.
    let sceneView: ARSCNView
    
    /// A reference to the main controller.
    let controller: MainController
    
    /// The object that is tracked for use by the pan and rotation gestures.
    var trackedObject: VirtualObject?
    
    /// The tracked screen position used to update the `trackedObject`'s position.
    private var currentTrackingPosition: CGPoint?
    
    // MARK: - Initialization
    
    init(sceneView: ARSCNView, controller: MainController) {
        self.sceneView = sceneView
        self.controller = controller
        super.init()
        
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        sceneView.addGestureRecognizer(rotationGesture)
    }
}


// MARK: - Gesture Actions

extension VirtualObjectInteraction {
    @objc func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case.began:
            break
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            
            // Move an object if the displacement threshold has been met.
            translate(object, basedOn: updatedTrackingPosition(for: object, from: gesture))
            
            gesture.setTranslation(.zero, in: sceneView)
        case .changed:
            // Ignore the pan gesture until the displacement threshold is exceeded.
            break
        case .ended:
            fallthrough
        default:
            // Reset the current tracking position.
            currentTrackingPosition = nil
        }
    }
        
    /// For looking down on the object (99% of all use cases), you subtract the angle.
    /// To make rotation also work correctly when looking from below the object one would have to
    /// flip the sign of the angle depending on whether the object is above or below the camera.
    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard let trackedObject = trackedObject else { return }
        guard gesture.state == .changed else { return }
        
        trackedObject.objectRotation -= Float(gesture.rotation)
        gesture.rotation = 0
    }
}

// MARK: - UIGestureRecognizerDelegate

extension VirtualObjectInteraction: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }
}

// MARK: - Update Object Position
extension VirtualObjectInteraction {
    func updatedTrackingPosition(for object: VirtualObject, from gesture: UIPanGestureRecognizer) -> CGPoint {
        let translation = gesture.translation(in: sceneView)
        let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
        let updatedPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
        
        currentTrackingPosition = updatedPosition
        return updatedPosition
    }
    
    func translate (_ object: VirtualObject, basedOn screenPos: CGPoint) {
        // Update the object by using a one-time position request.
        guard let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment) else { return }
        guard let result = sceneView.session.raycast(query).first else { return }
        
        object.simdWorldTransform = result.worldTransform
    }
}