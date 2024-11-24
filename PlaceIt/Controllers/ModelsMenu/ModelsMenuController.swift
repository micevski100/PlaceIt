//
//  ModelsMenuController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 22.11.24.
//

import UIKit
import SnapKit

protocol ModelsMenuControllerDelegate: AnyObject {
    func didSelectModel(modelUrl: URL?)
}

class ModelsMenuController: BaseController<ModelsMenuView> {
    
    // MARK: - Properties
    
    let isSectionedController: Bool!
    let dirURL: URL!
    private lazy var data: [URL] = {
        do {
            return try FileManager()
                .contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
                .filter{ $0.hasDirectoryPath }
        } catch {
            return []
        }
    }()
    
    weak var delegate: ModelsMenuControllerDelegate?
    
    // MARK: - Lifecycle
    
    class func factoryController(dirURL: URL, isSectionedController: Bool = false, delegate: ModelsMenuControllerDelegate) -> UINavigationController {
        let controller = ModelsMenuController(dirURL: dirURL, isSectionedController: isSectionedController)
        controller.delegate = delegate
        let mainCOntroller = UINavigationController(rootViewController: controller)
        return mainCOntroller
    }
    
    required init(dirURL: URL, isSectionedController: Bool = false) {
        self.dirURL = dirURL
        self.isSectionedController = isSectionedController
        super.init(nibName: nil, bundle: nil)
        super.viewDidLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .black
        
        self.contentView.collectionView.register(ModelsMenuCollectionCell.self, forCellWithReuseIdentifier: ModelsMenuCollectionCell.reuseIdentifier)
        self.contentView.collectionView.delegate = self
        self.contentView.collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

// MARK: - UICollectionViewDatasource, UICollectionViewDelegate

extension ModelsMenuController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let url: URL = data[indexPath.row]
        let image: UIImage? = getThumbImage(at: url)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ModelsMenuCollectionCell.reuseIdentifier, for: indexPath) as! ModelsMenuCollectionCell
        cell.setup(url.lastPathComponent, image)
        cell.controller = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as! ModelsMenuCollectionCell
        
        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
            delegate?.didSelectModel(modelUrl: nil)
            return false
        }
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSectionedController {
            let url = data[indexPath.row]
            let controller = ModelsMenuController(dirURL: url)
            controller.delegate = delegate
            self.navigationController?.pushViewController(controller, animated: true)
        } else {
            guard let modelUrl = getModelUrl(at: data[indexPath.row]) else { return }
            delegate?.didSelectModel(modelUrl: modelUrl)
        }
    }
}

// MARK: - Helpers

extension ModelsMenuController {
    func getThumbImage(at url: URL) -> UIImage? {
        let supportedExtensions = ["jpg", "jpeg", "png"]
        let imageUrl: URL? = FileManager()
            .enumerator(at: url,
                        includingPropertiesForKeys: [],
                        options: .skipsSubdirectoryDescendants)!
            .map { $0 as! URL }
            .first {
                $0.isFileURL &&
                $0.lastPathComponent.contains(url.lastPathComponent) &&
                supportedExtensions.contains($0.pathExtension)
            }
        
        guard let imageUrl else { return nil }
        return UIImage(contentsOfFile: imageUrl.path)
    }
    
    func getModelUrl(at url: URL) -> URL? {
        return FileManager()
            .enumerator(at: url,
                        includingPropertiesForKeys: [],
                        options: .skipsSubdirectoryDescendants)!
            .map { $0 as! URL }
            .first {
                $0.isFileURL &&
                $0.pathExtension == "dae"
            }
    }
}
