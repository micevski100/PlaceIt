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
    var showModelsMenuButton: UIButton!
    
    // MARK: - Layout
    override func setupViews() {
        
        sceneView = ARSCNView()
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        sceneView.showsStatistics = true
        sceneView.isUserInteractionEnabled = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.addSubview(sceneView)
        
        showModelsMenuButton = UIButton()
        showModelsMenuButton.setImage(UIImage(named: "addButtonImage"), for: [])
        showModelsMenuButton.setImage(UIImage(named: "addButtonImagePressed"), for: .selected)
        self.addSubview(showModelsMenuButton)
    }
    
    override func setupConstraints() {
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        showModelsMenuButton.snp.makeConstraints { make in
            make.bottom.right.equalTo(self.safeAreaLayoutGuide).inset(20)
            make.width.height.equalTo(60)
        }
    }
}
