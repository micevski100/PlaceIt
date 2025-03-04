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
    let sceneView: ARView
    
    /// A reference to the main controller.
    let controller: MainController
    
    /// The object that is tracked for use by the pan and rotation gestures.
    var trackedObject: VirtualObject? {
        didSet {
            guard oldValue != trackedObject else { return }
            toggleHighlight(for: oldValue)
            toggleHighlight(for: trackedObject)
            
            actionPanel.removeFromParentNode()
            actionPanel.position = SCNVector3Zero
            
            guard let trackedObject else { return }
           
            let panelOffsetY: Float = 0.15
            let trackedObjectHeight = trackedObject.boundingBox.max.y - trackedObject.boundingBox.min.y
            
            let panelWorldPosition = SCNVector3(
                x: trackedObject.worldPosition.x,
                y: trackedObject.worldPosition.y + trackedObjectHeight + panelOffsetY,
                z: trackedObject.worldPosition.z)
            let panelLocalPosition = trackedObject.convertPosition(panelWorldPosition, from: nil)
            
            actionPanel.position = panelLocalPosition
            let x = findMaterial(in: trackedObject, withName: "base")
            actionPanel.textureNode.geometry?.materials = [x!]
            actionPanel.addAppearAnimation(from: panelLocalPosition)
            trackedObject.addChildNode(actionPanel)
        }
    }
    
    func findMaterial(in object: VirtualObject, withName materialName: String) -> SCNMaterial? {
        var foundMaterial: SCNMaterial? = nil
        object.enumerateChildNodes { child, _ in
            child.geometry?.materials.forEach({ material in
                if material.name?.lowercased() == materialName.lowercased() {
                    foundMaterial = material
                    return
                }
            })
        }
        return foundMaterial
    }
    
    var actionPanel: VirtualObjectActionPanel = VirtualObjectActionPanel()
    
    /// The tracked screen position used to update the `trackedObject`'s position.
    private var currentTrackingPosition: CGPoint?
    
    // MARK: - Initialization
    
    init(sceneView: ARView, controller: MainController) {
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
        guard let trackedObject, let result = sceneView
            .hitTest(location, options: nil)
            .first(where: {
                $0.node.name == "delete" ||
                $0.node.name == "copy" ||
                $0.node.name == "texture"
            }) else { return }
        
        switch result.node.name {
        case "delete":
            controller.virtualObjectLoader.removeObject(trackedObject)
            self.trackedObject = nil
        case "copy":
            let objectWidth = trackedObject.boundingBox.max.x - trackedObject.boundingBox.min.x
            let offset: Float = objectWidth - 0.2
            let position = SCNVector3(trackedObject.position.x + offset, trackedObject.position.y, trackedObject.position.z)
            
            controller.placeObject(with: trackedObject.referenceURL, at: position) { object in
                self.trackedObject = object
            }
        case "texture":
            let sheetController = EditVirtualObjectController.factoryController(trackedObject, self)
            if let sheet = sheetController.sheetPresentationController {
                sheet.detents = [.custom { _ in return UIScreen.main.bounds.height * 0.3 }]
                sheet.prefersGrabberVisible = true
            }
            self.controller.present(sheetController, animated: true)
            break
        default:
            break
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

// MARK: - Highlight Technique

extension VirtualObjectInteraction {
    /// Highlights`VirtualObject` that's ready for interaction.
    func toggleHighlight(for object: VirtualObject?) {
        guard let object = object else { return }
        
        let highlightMaskValue = 2
        let normalMaskValue = 1
        
        if object.childNodes.first!.categoryBitMask == highlightMaskValue {
            // unhighlight
            object.childNodes.first!.setCategoryBitMaskForAllHierarchy(normalMaskValue)
        } else if object.childNodes.first!.categoryBitMask == normalMaskValue {
            // highlight
            object.childNodes.first!.setCategoryBitMaskForAllHierarchy(highlightMaskValue)
        } else {
            fatalError("Unsopported category bit mask value")
        }
    }
}

extension VirtualObjectInteraction: EditVirtualObjectDelegate {
    func didChangeTexture(_ object: VirtualObject) {
        guard let trackedObject else { return }
        let url = object.referenceURL
        
        controller.virtualObjectLoader.loadObject(with: url) { [unowned self] object in
            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene]) { _ in
                    DispatchQueue.main.async {
                        object.position = trackedObject.position
                        object.rotation = trackedObject.rotation
                        object.objectRotation = trackedObject.objectRotation
                        object.anchor = trackedObject.anchor
                        
                        let offset: Float = 0.15
                        let trackedObjectHeight = object.boundingBox.max.y - object.boundingBox.min.y
                        
                        let panelWorldPosition = SCNVector3(
                            x: object.worldPosition.x,
                            y: object.worldPosition.y + trackedObjectHeight + offset,
                            z: object.worldPosition.z)
                        let panelLocalPosition = object.convertPosition(panelWorldPosition, from: nil)
                        
                        let x = self.findMaterial(in: object, withName: "base")
                        self.actionPanel.textureNode.geometry?.materials = [x!]
                        
                        self.actionPanel.position = panelLocalPosition

                        

                        self.controller.virtualObjectLoader.removeObject(trackedObject, false)
                        self.trackedObject = object
                        
                        self.sceneView.scene.rootNode.addChildNode(object)
                        object.addChildNode(self.actionPanel)
                    }
                }
            } catch {
                print("Failed to change texture for object \(trackedObject.referenceURL)")
            }
        }
    }
}
