//
//  EditVirtualObjectCollectionItemCell.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 26.1.25.
//

import UIKit
import SceneKit
import SnapKit
import Foundation

class EditVirtualObjectCollectionItemCell: UICollectionViewCell {
    
    static let reuseIdentifier = "EditVirtualObjectCollectionItemCell"
    
    let virtualObjectLoader = VirtualObjectLoader()
    var object: VirtualObject!
    
    var containerView: UIVisualEffectView!
    var sceneView: SCNView!
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                UIView.animate(withDuration: 0.3) {
//                    self.contentView.layer.borderWidth = 1
//                    self.contentView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
                    self.containerView.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
                }
            }
            else {
                UIView.animate(withDuration: 0.3) {
//                    self.contentView.layer.borderWidth = 0
//                    self.contentView.layer.borderColor = UIColor.clear.cgColor
                    self.containerView.backgroundColor = .clear
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        let blurrEffect = UIBlurEffect(style: .light)
        containerView = UIVisualEffectView(effect: blurrEffect)
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        containerView.isUserInteractionEnabled = true
        self.contentView.addSubview(containerView)
        
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.4, 1.1)
        cameraNode.camera?.fieldOfView = 50 // Moderate field of view
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        scene.rootNode.addChildNode(cameraNode)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.type = .directional
        lightNode.light?.intensity = 1000
//        lightNode.eulerAngles = SCNVector3(- / 4, 0, 0)
        lightNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 500 // Lower intensity for subtle effect
        scene.rootNode.addChildNode(ambientLightNode)
        
        sceneView = SCNView()
        sceneView.scene = scene
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
//        self.contentView.addSubview(sceneView)
        containerView.contentView.addSubview(sceneView)
    }
    
    func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setup(_ objectURL: URL ) {
        virtualObjectLoader.loadObject(with: objectURL) { object in
            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene]) { _ in
                    DispatchQueue.main.async {
                        self.object = object
                        object.scale = SCNVector3(0.7, 0.7, 0.7)
                        object.position = SCNVector3(0, 0, 0)
                        object.eulerAngles.x = Float.pi / 12
                        
                        let minBounds = object.boundingBox.min
                        let maxBounds = object.boundingBox.max

                        let objectCenter = SCNVector3(
                            (minBounds.x + maxBounds.x) / 2,
                            (minBounds.y + maxBounds.y) / 2,
                            (minBounds.z + maxBounds.z) / 2
                        )
                        
                        let sceneSize = self.sceneView.bounds.size
                        let screenCenter = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)

                        // Convert screen center to 3D world space
                        let worldCenter = self.sceneView.unprojectPoint(SCNVector3(Float(screenCenter.x), Float(screenCenter.y), 0))

                        
                        let offsetX = worldCenter.x - objectCenter.x
                        let offsetY = worldCenter.y - objectCenter.y
                        let offsetZ = -0.2 //-1.5 // Keep depth fixed

                        object.position = SCNVector3(offsetX, offsetY, Float(offsetZ))

                        
                        self.sceneView.scene!.rootNode.addChildNode(object)
                    }
                }
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }
        }
    }
    
    func placeObject(with url: URL, at position: SCNVector3, completion: @escaping (VirtualObject) -> Void = { _ in }) {
        virtualObjectLoader.loadObject(with: url) { [unowned self] object in
            do {
                let scene = try SCNScene(url: object.referenceURL, options: nil)
                self.sceneView.prepare([scene]) { _ in
                    DispatchQueue.main.async {
                        object.position = position
                        print(object.boundingBox.max.x)
                        self.sceneView.scene!.rootNode.addChildNode(object)
                        
                        completion(object)
                    }
                }
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        object = nil
        self.isSelected = false
    }
}
