//
//  EditModelCollectionItemCell.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 16.12.24.
//

import UIKit
import SceneKit
import SnapKit

class EditModelCollectionItemCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "EditModelCollectionItemCell"
    var selectedObjectURL: URL!
    var selectedObjectTexture: VirtualObjectTexture!
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                UIView.animate(withDuration: 0.3) {
                    self.contentView.layer.borderWidth = 1
                    self.contentView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
                }
            }
            else {
                UIView.animate(withDuration: 0.3) {
                    self.contentView.layer.borderWidth = 0
                    self.contentView.layer.borderColor = UIColor.clear.cgColor
                }
            }
        }
    }
    
    
    var sceneView: SCNView!
    
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        sceneView = SCNView()
        sceneView.scene = SCNScene()
        self.contentView.addSubview(sceneView)
    }
    
    func setupConstraints() {
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setup(_ selectedObjectURL: URL, _ selectedObjectTexture: VirtualObjectTexture) {
        self.selectedObjectURL = selectedObjectURL
        self.selectedObjectTexture = selectedObjectTexture
        
        guard let scene = try? SCNScene(url: selectedObjectURL) else { return }
        
        let virtualObject = VirtualObject(url: selectedObjectURL)
        let rootNode = SCNNode()
        scene.rootNode.childNodes.forEach { rootNode.addChildNode($0) }
        virtualObject.addChildNode(rootNode)
        virtualObject.applyTexture(selectedObjectTexture)
        virtualObject.position = SCNVector3(0, 0, -5)
        sceneView.scene?.rootNode.addChildNode(virtualObject)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
    }
}
