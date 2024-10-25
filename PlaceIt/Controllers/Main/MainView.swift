//
//  MainView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import UIKit
import ARKit
import SnapKit

class MainView: BaseView {
    
    // MARK: - UI Elements
    var sceneView: ARSCNView!
    
    // MARK: - Layout
    override func setupViews() {
        self.backgroundColor = .white
        
        sceneView = ARSCNView()
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.addSubview(sceneView)
    }
    
    override func setupConstraints() {
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
