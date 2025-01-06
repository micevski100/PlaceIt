//
//  VirtualObjectLoader.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 6.1.25.
//

import Foundation
import ARKit

/// Loads and tracks multiple `VirtualObject`'s on a background queue.
class VirtualObjectLoader {
    
    // MARK: - Properties
    
    private(set) var loadedObjects: [VirtualObject] = []
    
    
    // MARK: - Load Object
    
    /// Loads a `VirtualObject` on a background queue. `completion` handler is invoked on a
    /// background queue once a virtual object is created.
    func loadObject(with url: URL, completion: @escaping (VirtualObject) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let referenceNode = SCNReferenceNode(url: url)!
            referenceNode.load()
            
            let rootNode = SCNNode()
            referenceNode.childNodes.forEach { rootNode.addChildNode($0) }
            
            let object = VirtualObject(url: url)
            object.addChildNode(rootNode)
            
            self.loadedObjects.append(object)
            completion(object)
        }
    }
    
    // MARK: - Remove Object
    
    func removeObject(_ object: VirtualObject) {
        guard let objectIndex = loadedObjects.firstIndex(of: object) else { return }
        object.animateScaleDown()
        
        // Delay object removal until the animation is completed.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            object.removeFromParentNode()
        }
        
        // Recoup resources allocated by the object.
        let referenceNode = SCNReferenceNode(url: object.referenceURL)
        referenceNode?.unload()
        loadedObjects.remove(at: objectIndex)
    }
    
    // MARK: - Set Loaded Objects
    
    func setLoadedObjects(_ objects: [VirtualObject]) {
        loadedObjects = objects
    }
}
