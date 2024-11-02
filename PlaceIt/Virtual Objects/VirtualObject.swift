//
//  VirtualObject.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 25.10.24.
//

import Foundation
import ARKit
import SceneKit

class VirtualObject: SCNNode {
    
    let id: UUID!
    
    /// The object's corresponding ARAnchor.
    var anchor: ARAnchor?
    
    /// The alignments that are allowed for a virtual object.
    var allowedAlignment: ARRaycastQuery.TargetAlignment {
        .horizontal
    }
    
    /// Rotates the first child node of a virtual object.
    /// - Note: For correct rotation on horizontal and vertical surfaces, rotate around
    /// local y rather than world y.
    var objectRotation: Float {
        get {
            return childNodes.first!.eulerAngles.y
        }
        set (newValue) {
            childNodes.first!.eulerAngles.y = newValue
        }
    }
    
    override init() {
        self.id = UUID()
        super.init()
        
        let geometry = SCNSphere(radius: 0.05) // Example geometry
        self.geometry = geometry
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VirtualObject {
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }
    
    func toggleHighlight() {
        let highlightMaskValue = 2
        let normalMaskValue = 1
        
        if childNodes.first!.categoryBitMask == highlightMaskValue {
            // unhighlight
            childNodes.first!.setCategoryBitMaskForAllHierarchy(normalMaskValue)
        } else if childNodes.first!.categoryBitMask == normalMaskValue {
            // highlight
            childNodes.first!.setCategoryBitMaskForAllHierarchy(highlightMaskValue)
        } else {
            fatalError("Unsopported category bit mask value")
        }
    }
}
