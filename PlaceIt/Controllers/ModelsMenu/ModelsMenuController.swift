//
//  ModelsMenuController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 26.10.24.
//

import UIKit

class ModelsMenuController: BaseController<ModelsMenuView> {
    
    // MARK: - Properties
    
    var delegate: ModelsMenuControllerDelegate?
    
    let availableModelNames: [String] = {
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!
        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
        
        return fileEnumerator.compactMap { element in
            let url = element as! URL
            guard url.pathExtension == "dae" && !url.path.contains("lighting") else { return nil }
            return url.lastPathComponent.replacingOccurrences(of: ".dae", with: "")
        }
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollection()
    }
}

// MARK: - UICOllectioonViewDataSource and Delegate

extension ModelsMenuController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableModelNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ModelsMenuItemCell.reuseIdentifier,
            for: indexPath
        ) as! ModelsMenuItemCell
        
        cell.setup("test")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ModelsMenuItemCell.reuseIdentifier, for: indexPath) as! ModelsMenuItemCell
        
        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
            delegate?.didSelectModel(modelName: nil)
            return false
        }
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectModel(modelName: availableModelNames[indexPath.row])
    }
}

// MARK: - Helpers

extension ModelsMenuController {
    func setupCollection() {
        self.contentView.collectionView.register(
            ModelsMenuItemCell.self,
            forCellWithReuseIdentifier: ModelsMenuItemCell.reuseIdentifier
        )
        self.contentView.collectionView.delegate = self
        self.contentView.collectionView.dataSource = self
    }
}

// MARK: - Delegate

protocol ModelsMenuControllerDelegate {
    func didSelectModel(modelName: String?)
}
