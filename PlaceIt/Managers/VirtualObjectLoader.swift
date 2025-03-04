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
    
    func removeObject(_ object: VirtualObject, _ withAnimation: Bool = true) {
        guard let objectIndex = loadedObjects.firstIndex(of: object) else { return }
        
        if (withAnimation) {
            object.animateScaleDown()
            
            // Delay object removal until the animation is completed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                object.removeFromParentNode()
            }
        } else {
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
    
    // MARK: - Get Object Textures
    func getTextures(for object: VirtualObject) -> [URL] {
        let parentDirectory = object.referenceURL.deletingLastPathComponent()
        let fileEnumerator = FileManager().enumerator(at: parentDirectory, includingPropertiesForKeys: [])!
        
        return fileEnumerator.compactMap { element in
            let url = element as! URL

            guard url.pathExtension == "scn" else { return nil }

            return url
        }
    }
}
