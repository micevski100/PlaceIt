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
    
    override init() {
        self.id = UUID()
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
