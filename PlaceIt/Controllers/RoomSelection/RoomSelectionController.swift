//
//  RoomSelectionController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 17.11.24.
//

import UIKit
import TipKit

class RoomSelectionController: BaseController<RoomSelectionView> {
    
    private let rooms: [Room] = {
        do {
            return try RoomManager.shared.listAll()
        } catch {
            return []
        }
//        guard let rooms = try RoomManager.shared.listAll() else { return [] }
//        return rooms
    }()
    
    var addRoomTip = AddRoomTip()
    
    class func factoryController() -> UINavigationController {
        let controller = RoomSelectionController()
        let mainController = UINavigationController(rootViewController: controller)
        return mainController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Pick a Room"
        
        self.contentView.collectionView.register(RoomSelectionCollectionItemCell.self, forCellWithReuseIdentifier: RoomSelectionCollectionItemCell.identifier)
        self.contentView.collectionView.register(RoomSelectionCollectionAddItemCell.self, forCellWithReuseIdentifier: RoomSelectionCollectionAddItemCell.identifier)
        self.contentView.collectionView.delegate = self
        self.contentView.collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
}

extension RoomSelectionController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rooms.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!
        
        if indexPath.row < rooms.count {
            let x: RoomSelectionCollectionItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: RoomSelectionCollectionItemCell.identifier, for: indexPath) as! RoomSelectionCollectionItemCell
            x.setup(rooms[indexPath.row])
            x.delegate = self
            cell = x
        } else {
            let x: RoomSelectionCollectionAddItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: RoomSelectionCollectionAddItemCell.identifier, for: indexPath) as! RoomSelectionCollectionAddItemCell
            x.delegate = self
            cell = x
            
            Task { @MainActor in
                for await shouldDisplay in addRoomTip.shouldDisplayUpdates {
                    guard shouldDisplay else { continue }
                    guard self.rooms.isEmpty else { continue }
                    
                    let controller = TipUIPopoverViewController(addRoomTip, sourceItem: cell)
                    self.present(controller, animated: true)
                }
            }
        }
        
        return cell
    }
}

extension RoomSelectionController: RoomSelectionCollectionItemCellDelegate, RoomSelectionCollectionAddItemCellDelegate {
    func didSelectRoom(_ room: Room) {
        let controller = MainController.factoryController(room)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func addRoom() {
        addRoomTip.invalidate(reason: .actionPerformed)
        let controller = CreateRoomController.factoryController()
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
