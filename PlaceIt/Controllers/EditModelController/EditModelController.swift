//
//  EditModelController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 16.12.24.
//

import UIKit

class EditModelController: BaseController<EditModelView> {
    
    var delegate: EditModelDelegate?
    var selectedObject: VirtualObject!
    var textures: [VirtualObjectTexture]!
    var selectedObjectURL: URL!
    
    class func factoryController(_ selectedObject: VirtualObject, _ delegate: EditModelDelegate?) -> BaseController<EditModelView> {
        let controller = EditModelController()
        controller.selectedObject = selectedObject
        controller.selectedObjectURL = selectedObject.referenceURL!
        controller.delegate = delegate
        let object = VirtualObject(url: selectedObject.referenceURL!)
        controller.textures = ModelsManager.shared.getTextures(for: object)
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentView.collectionView.register(EditModelCollectionItemCell.self, forCellWithReuseIdentifier: EditModelCollectionItemCell.reuseIdentifier)
        self.contentView.collectionView.delegate = self
        self.contentView.collectionView.dataSource = self
    }
}

extension EditModelController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return textures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EditModelCollectionItemCell.reuseIdentifier, for: indexPath) as! EditModelCollectionItemCell
        let texture = textures[indexPath.row]
        cell.setup(selectedObjectURL, texture)
        if (selectedObject.appliedTexture == texture) {
            cell.isSelected = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let texture = textures[indexPath.row]
        delegate?.didSelectTexture(texture)
    }
}

protocol EditModelDelegate: AnyObject {
    func didSelectTexture(_ texture: VirtualObjectTexture)
}
