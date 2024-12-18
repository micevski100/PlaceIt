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
    var trackedObject: VirtualObject? {
        didSet {
            guard oldValue != trackedObject else { return }
            oldValue?.toggleHighlight()
            trackedObject?.toggleHighlight()
            
            actionPanel.removeFromParentNode()
            actionPanel.position = SCNVector3Zero
            
            guard let trackedObject else { return }
           
            let offset: Float = 0.15
            let trackedObjectHeight = trackedObject.boundingBox.max.y - trackedObject.boundingBox.min.y
            
            let panelWorldPosition = SCNVector3(
                x: trackedObject.worldPosition.x,
                y: trackedObject.worldPosition.y + trackedObjectHeight + offset,
                z: trackedObject.worldPosition.z)
            let panelLocalPosition = trackedObject.convertPosition(panelWorldPosition, from: nil)
            
            actionPanel.setup(trackedObject.appliedTexture!, ModelsManager.shared.getTextures(for: trackedObject))
            actionPanel.position = panelLocalPosition
            trackedObject.addChildNode(actionPanel)
            actionPanel.addAppearAnimation(from: panelLocalPosition)
        }
    }
    
    var actionPanel: VirtualObjectActionPanel = VirtualObjectActionPanel()
    
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
        
        loadHighlightTechnique()
    }
    
    /// Loads the technique that is used to achieve a highlight effect around selected `VirtualObject`.
    private func loadHighlightTechnique() {
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
            // Update the object's position when the user stops panning.
            guard let object = trackedObject else { break }
            controller.updateQueue.async {
                self.sceneView.addOrUpdateAnchor(for: object)
            }
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
    
    func didTap(location: CGPoint) {
        guard let trackedObject else { return }
        let hitResults = sceneView.hitTest(location, options: nil)
        for result in hitResults {
            if let nodeName = result.node.name {
                switch nodeName {
                case "copy":
                    let objectWidth = trackedObject.boundingBox.max.x - trackedObject.boundingBox.min.x
                    let offset: Float = objectWidth - 0.2
                    let position = SCNVector3(trackedObject.position.x + offset, trackedObject.position.y, trackedObject.position.z)
                    
                    self.trackedObject = nil
                    let copyObject = trackedObject.clone()
                    copyObject.position = position
                    
                    controller.placeVirtualObject(object: copyObject) { object in
                        self.trackedObject = object
                    }
                    break
                case "delete":
                    controller.removeVirtualObject(trackedObject)
                    self.trackedObject = nil
                case "texture":
                    let newController = EditModelController.factoryController(trackedObject, self)
                    if let sheet = newController.sheetPresentationController {
                        sheet.detents = [.custom { _ in return UIScreen.main.bounds.height * 0.3 }]
                        sheet.prefersGrabberVisible = true
                    }
                    print("PRESENTING")
                    controller.present(newController, animated: true)
                    break
                default:
                    break
                }
            }
        }
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
    private func updatedTrackingPosition(for object: VirtualObject, from gesture: UIPanGestureRecognizer) -> CGPoint {
        let translation = gesture.translation(in: sceneView)
        let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
        let updatedPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
        
        currentTrackingPosition = updatedPosition
        return updatedPosition
    }
    
    private func translate (_ object: VirtualObject, basedOn screenPos: CGPoint) {
        // Update the object by using a one-time position request.
        guard let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment) else { return }
        guard let result = sceneView.session.raycast(query).first else { return }
        
        object.simdWorldTransform = result.worldTransform
    }
}

extension VirtualObjectInteraction: EditModelDelegate {
    func didSelectTexture(_ texture: VirtualObjectTexture) {
        guard let trackedObject else { return }
        trackedObject.applyTexture(texture)
    }
}
