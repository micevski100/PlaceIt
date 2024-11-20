//
//  Plane.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//
///  SCNNode subclass used for visualizing detected planes in a Tron style.

import SceneKit
import ARKit

class Plane: SCNNode {
    
    var anchor: ARPlaneAnchor?
    var planeGeometry: SCNPlane?
    
    init(with anchor: ARPlaneAnchor) {
        super.init()
        self.anchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.planeExtent.width), height: CGFloat(anchor.planeExtent.height))
        
        // TODO: Unable to load tron_grid. Glitches and dissapears from the scene.
        let material = SCNMaterial()
        if let img = UIImage(named: "tron_grid") {
            material.diffuse.contents = img
        }
        self.planeGeometry?.materials = [material]
        
        
//        self.planeGeometry?.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        // Planes in SceneKit are vertical by default so we need to rotate 90degrees to match
        // planes in ARKit
        planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0)
        
        self.setTextureScale()
        self.addChildNode(planeNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with anchor: ARPlaneAnchor) {
        // As the user moves around the extend and location of the plane
        // may be updated. We need to update our 3D geometry to match the
        // new parameters of the plane.
        self.planeGeometry?.width = CGFloat(anchor.planeExtent.width)
        self.planeGeometry?.height = CGFloat(anchor.planeExtent.height)
        
        // When the plane is first created it's center is 0,0,0 and the nodes
        // transform contains the translation parameters. As the plane is updated
        // the planes translation remains the same but it's center is updated so
        // we need to update the 3D geometry position
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        self.setTextureScale()
    }
    
    func setTextureScale() {
        guard let planeGeometry = self.planeGeometry, let material = planeGeometry.materials.first else {
            return
        }
        
        let width = planeGeometry.width
        let height = planeGeometry.height
        
        // As the width/height of the plane updates, we want our tron grid material to
        // cover the entire plane, repeating the texture over and over. Also if the
        // grid is less than 1 unit, we don't want to squash the texture to fit, so
        // scaling updates the texture co-ordinates to crop the texture in that case
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
}
