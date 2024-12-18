//
//  EditModelView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 16.12.24.
//

import UIKit
import SceneKit
import SnapKit

//class EditModelView: BaseView {
//    
//    var selectedObjectURL: URL!
//    
//    var sceneView: SCNView!
//    
//    override func setupViews() {
//        self.backgroundColor = .white
//        
//        sceneView = SCNView()
//        sceneView.scene = SCNScene()
//        self.addSubview(sceneView)
//    }
//    
//    override func setupConstraints() {
//        sceneView.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//            make.width.height.equalTo(150)
//        }
//    }
//    
//    func setup(_ selectedObjectURL: URL) {
//        self.selectedObjectURL = selectedObjectURL
//        guard let scene = try? SCNScene(url: selectedObjectURL) else {
//            return
//        }
//        
//        let virtualObject = VirtualObject(url: selectedObjectURL)
//        let rootNode = SCNNode()
//        scene.rootNode.childNodes.forEach { rootNode.addChildNode($0) }
//        virtualObject.addChildNode(rootNode)
//        let texture = ModelsManager.shared.getTextures(for: virtualObject)[0]
//        virtualObject.applyTexture(texture)
//        virtualObject.position = SCNVector3(0, 0, -5)
//        sceneView.scene?.rootNode.addChildNode(virtualObject)
//        
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        cameraNode.position = SCNVector3(0, 0, 10)
//        scene.rootNode.addChildNode(cameraNode)
//
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light?.type = .omni
//        lightNode.position = SCNVector3(0, 10, 10)
//        scene.rootNode.addChildNode(lightNode)
//        
//        sceneView.autoenablesDefaultLighting = true
//        sceneView.allowsCameraControl = true
//    }
//}

class EditModelView: BaseView {

    var titleLabel: UILabel!
    var closeButton: UIButton!
    var collectionView: UICollectionView!
    
    override func setupViews() {
        self.backgroundColor = UIColor.init(hex: 0xF8F9FC)
        
        titleLabel = UILabel()
        titleLabel.text = "Color"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        self.addSubview(titleLabel)
        
        closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "x.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        self.addSubview(closeButton)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        self.addSubview(collectionView)
    }
    
    override func setupConstraints() {
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(10)
            make.width.height.equalTo(70)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(120))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
        group.interItemSpacing = .fixed(10)
        
        // Sections
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
