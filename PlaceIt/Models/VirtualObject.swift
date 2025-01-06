//
//  VirtualObject.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 25.10.24.
//

import Foundation
import ARKit
import SceneKit

/// A `SCNNode` subclass for virtual objects placed into the AR scene.
class VirtualObject: SCNNode {
    
    // MARK: - Properties
    
    /// A unique identifier for the virtual object..
    let id: UUID
    
    /// The model name derived from the `referenceURL`.
    var modelName: String {
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".dae", with: "")
    }
    
    /// The file URL of the 3D model associated with the virtual object.
    var referenceURL: URL
    
    /// The object's corresponding ARAnchor.
    var anchor: ARAnchor?
    
    /// The alignments that are allowed for a virtual object.
    var allowedAlignment: ARRaycastQuery.TargetAlignment {
        .horizontal
    }
    
    /// Rotates the first child node of a virtual object.
    /// - Note: For correct rotation on horizontal and vertical surfaces,
    /// rotate around local y rather than world y.
    var objectRotation: Float {
        get {
            return childNodes.first!.eulerAngles.y
        }
        set (newValue) {
            childNodes.first!.eulerAngles.y = newValue
        }
    }
    
    // MARK: - Initialization
    
    required init(url: URL) {
        self.referenceURL = url
        self.id = UUID()
        super.init()
        
        animateScaleUp()
    }
    
    private override init() {
        id = UUID()
        referenceURL = URL(fileURLWithPath: "/dev/null")
        super.init()
        
        animateScaleUp()
    }
    
    // MARK: - NSSecureCoding
    
    required init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(of: [NSUUID.self], forKey: "id") as? UUID else { return nil}
        guard let referenceURL = aDecoder.decodeObject(of: [NSURL.self], forKey: "referenceURL") as? URL else { return nil }
        guard let anchor = aDecoder.decodeObject(of: [ARAnchor.self], forKey: "anchor") as? ARAnchor else { return nil }
        
        self.id = id
        self.referenceURL = referenceURL
        self.anchor = anchor
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(id, forKey: "id")
        aCoder.encode(referenceURL, forKey: "referenceURL")
        aCoder.encode(anchor, forKey: "anchor")
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    // MARK: - NSCopying
    
    override func clone() -> Self {
        let clone = super.clone()
        clone.referenceURL = self.referenceURL
        if let geometry = self.geometry {
            let sources = geometry.sources
            let elements = geometry.elements
            
            let copiedGeometry = SCNGeometry(sources: sources, elements: elements)
            copiedGeometry.materials = geometry.materials.map { $0.copy() as! SCNMaterial }
            
            clone.geometry = copiedGeometry
        }
        return clone
    }
}

// MARK: - Helpers

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
}

extension VirtualObject {
    func animateScaleUp() {
        let originalScale = scale
        scale = SCNVector3(0, 0, 0)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        scale = originalScale
        SCNTransaction.commit()
    }
    
    func animateScaleDown() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        scale = SCNVector3(0, 0, 0)
        SCNTransaction.commit()
    }
}
