//
//  EditVirtualObjectController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 26.1.25.
//

import UIKit
import SceneKit

class EditVirtualObjectController: BaseController<EditVirtualObjectView> {
    
    var object: VirtualObject!
    var delegate: EditVirtualObjectDelegate?
    var textures: [URL]!
    
    class func factoryController(_ object: VirtualObject, _ delegate: EditVirtualObjectDelegate?) -> BaseController<EditVirtualObjectView> {
        let controller = EditVirtualObjectController()
        controller.object = object
        controller.delegate = delegate
        controller.textures = VirtualObjectLoader().getTextures(for: object)
        return controller
   }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentView.collectionView.register(EditVirtualObjectCollectionItemCell.self, forCellWithReuseIdentifier: EditVirtualObjectCollectionItemCell.reuseIdentifier)
        self.contentView.collectionView.delegate = self
        self.contentView.collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedIndexPath = textures
            .firstIndex(where: { $0.lastPathComponent == object.referenceURL.lastPathComponent })
            .map({ it in IndexPath(row: it, section: 0)})
        
        self.contentView.collectionView.selectItem(at: selectedIndexPath, animated: true, scrollPosition: .top)
    }
}

extension EditVirtualObjectController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return textures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EditVirtualObjectCollectionItemCell.reuseIdentifier, for: indexPath) as! EditVirtualObjectCollectionItemCell
        let texture = textures[indexPath.row]
        cell.setup(texture)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let originalObject = self.object
        let cell = collectionView.cellForItem(at: indexPath) as! EditVirtualObjectCollectionItemCell
        guard let selectedTexturedObject = cell.object else { return }
//        applyTextures(from: selectedTexturedObject, to: originalObject)
        delegate?.didChangeTexture(selectedTexturedObject)
    }
    
    private func applyTextures(from sourceNode: SCNNode?, to destinationNode: SCNNode?) {
        guard let sourceNode, let destinationNode else { return }
        
        if let sourceGeometry = sourceNode.geometry, let destinationGeometry = destinationNode.geometry {
            destinationGeometry.materials = sourceGeometry.materials
        }
        
        applyTextures(from: sourceNode.childNodes.first, to: destinationNode.childNodes.first)
    }
}

protocol EditVirtualObjectDelegate {
    func didChangeTexture(_ object: VirtualObject)
}
