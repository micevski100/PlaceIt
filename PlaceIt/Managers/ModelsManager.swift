//
//  ModelsManager.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 13.12.24.
//
import Foundation

class NodeTexture: NSObject, NSSecureCoding, NSCopying {
    let nodeName: String
    let diffuse: URL?
    let metalness: URL?
    let normal: URL?
    let roughness: URL?
    
    static var supportsSecureCoding: Bool = true
    
    init(nodeName: String, diffuse: URL?, metalness: URL?, normal: URL?, roughness: URL?) {
        self.nodeName = nodeName
        self.diffuse = diffuse
        self.metalness = metalness
        self.normal = normal
        self.roughness = roughness
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let nodeName = aDecoder.decodeObject(of: NSString.self, forKey: "nodeName") as String? else { return nil }
        let diffuse = aDecoder.decodeObject(of: NSURL.self, forKey: "diffuse") as URL?
        let metalness = aDecoder.decodeObject(of: NSURL.self, forKey: "metalness") as URL?
        let normal = aDecoder.decodeObject(of: NSURL.self, forKey: "normal") as URL?
        let roughness = aDecoder.decodeObject(of: NSURL.self, forKey: "roughness") as URL?
        
        self.init(nodeName: nodeName, diffuse: diffuse, metalness: metalness, normal: normal, roughness: roughness)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(nodeName, forKey: "nodeName")
        coder.encode(diffuse, forKey: "diffuse")
        coder.encode(metalness, forKey: "metalness")
        coder.encode(normal, forKey: "normal")
        coder.encode(roughness, forKey: "roughness")
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return NodeTexture(nodeName: self.nodeName,
                           diffuse: self.diffuse,
                           metalness: self.metalness,
                           normal: self.normal,
                           roughness: self.roughness)
    }
}


class VirtualObjectTexture: NSObject, NSSecureCoding, NSCopying {
    let nodeTextures: [String: NodeTexture]
    
    static var supportsSecureCoding: Bool = true
    
    init(nodeTextures: [String: NodeTexture]) {
        self.nodeTextures = nodeTextures
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let nodeTextures = aDecoder.decodeObject(of: [NSDictionary.self, NSString.self, NodeTexture.self], forKey: "nodeTextures") as? [String: NodeTexture] else {
            return nil
        }
        self.init(nodeTextures: nodeTextures)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(nodeTextures, forKey: "nodeTextures")
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        // Perform a deep copy of nodeTextures
        let copiedNodeTextures = self.nodeTextures.mapValues { $0.copy() as! NodeTexture }
        return VirtualObjectTexture(nodeTextures: copiedNodeTextures)
    }
}



class ModelsManager: NSObject {
    static let shared = ModelsManager()
    
    private let fileManager = FileManager.default
    
    private override init() {}
    
    public func getTextures(for object: VirtualObject) -> [VirtualObjectTexture] {
        guard let objectReferenceURL = object.referenceURL else { return [] }

        let objectRootDirURL = objectReferenceURL.deletingLastPathComponent()
        let texturesRootDirURL = objectRootDirURL.appendingPathComponent("Textures")

        var virtualObjectTextures: [VirtualObjectTexture] = []

        // Fetch texture folders under "Textures"
        guard let textureFolders = try? fileManager.contentsOfDirectory(at: texturesRootDirURL, includingPropertiesForKeys: [.isDirectoryKey]) else { return [] }

        for textureFolder in textureFolders {
            // Fetch node texture folders
            guard let nodeFolders = try? fileManager.contentsOfDirectory(at: textureFolder, includingPropertiesForKeys: [.isDirectoryKey]) else { continue }

            var nodeTextures: [String: NodeTexture] = [:]

            for nodeFolder in nodeFolders {
                // Fetch all material files (diffuse, normal, roughness, etc.)
                guard let materialFiles = try? fileManager.contentsOfDirectory(at: nodeFolder, includingPropertiesForKeys: [.isRegularFileKey]) else { continue }

                // Map material file names to URLs
                var textureURLs: [String: URL] = [:]
                for materialFile in materialFiles {
                    let fileName = materialFile.lastPathComponent.lowercased()
                    if fileName.contains("diffuse") {
                        textureURLs["diffuse"] = materialFile
                    } else if fileName.contains("metalness") {
                        textureURLs["metalness"] = materialFile
                    } else if fileName.contains("normal") {
                        textureURLs["normal"] = materialFile
                    } else if fileName.contains("roughness") {
                        textureURLs["roughness"] = materialFile
                    }
                }

                let nodeTexture = NodeTexture(
                    nodeName: nodeFolder.lastPathComponent,
                    diffuse: textureURLs["diffuse"],
                    metalness: textureURLs["metalness"],
                    normal: textureURLs["normal"],
                    roughness: textureURLs["roughness"]
                )
                nodeTextures[nodeTexture.nodeName] = nodeTexture
            }

            let virtualObjectTexture = VirtualObjectTexture(nodeTextures: nodeTextures)
            virtualObjectTextures.append(virtualObjectTexture)
        }

        return virtualObjectTextures
    }
}


//struct VirtualObjectTexture {
//    let nodeTextures: [NodeTexture]
//}
//
//struct NodeTexture: Equatable {
//    let nodeName: String
//    let diffuse: URL?
//    let metalness: URL?
//    let normal: URL?
//    let roughness: URL?
//}
//
//class ModelsManager: NSObject {
//    static let shared = ModelsManager()
//    
//    private let fileManager = FileManager.default
//    
//    private override init() {}
//    
//    public func getTextures(for object: VirtualObject) -> [VirtualObjectTexture] {
//        guard let objectReferenceURL = object.referenceURL else { return [] }
//
//        let objectRootDirURL = objectReferenceURL.deletingLastPathComponent()
//        let texturesRootDirURL = objectRootDirURL.appendingPathComponent("Textures")
//
//        var virtualObjectTextures: [VirtualObjectTexture] = []
//
//        // Fetch texture folders under "Textures"
//        guard let textureFolders = try? fileManager.contentsOfDirectory(at: texturesRootDirURL, includingPropertiesForKeys: [.isDirectoryKey]) else { return [] }
//
//        for textureFolder in textureFolders {
//            // Fetch node texture folders
//            guard let nodeFolders = try? fileManager.contentsOfDirectory(at: textureFolder, includingPropertiesForKeys: [.isDirectoryKey]) else { continue }
//
//            var nodeTextures: [NodeTexture] = []
//
//            for nodeFolder in nodeFolders {
//                // Fetch all material files (diffuse, normal, rougness, etc.)
//                guard let materialFiles = try? fileManager.contentsOfDirectory(at: nodeFolder, includingPropertiesForKeys: [.isRegularFileKey]) else { continue }
//
//                // Map material file names to URLs
//                var textureURLs: [String: URL] = [:]
//                for materialFile in materialFiles {
//                    let fileName = materialFile.lastPathComponent.lowercased()
//                    if fileName.contains("diffuse") {
//                        textureURLs["diffuse"] = materialFile
//                    } else if fileName.contains("metalness") {
//                        textureURLs["metalness"] = materialFile
//                    } else if fileName.contains("normal") {
//                        textureURLs["normal"] = materialFile
//                    } else if fileName.contains("roughness") {
//                        textureURLs["roughness"] = materialFile
//                    }
//                }
//
//                let nodeTexture = NodeTexture(
//                    nodeName: nodeFolder.lastPathComponent,
//                    diffuse: textureURLs["diffuse"],
//                    metalness: textureURLs["metalness"],
//                    normal: textureURLs["normal"],
//                    roughness: textureURLs["roughness"]
//                )
//                nodeTextures.append(nodeTexture)
//            }
//
//            let virtualObjectTexture = VirtualObjectTexture(nodeTextures: nodeTextures)
//            virtualObjectTextures.append(virtualObjectTexture)
//        }
//
//        return virtualObjectTextures
//    }
//}
