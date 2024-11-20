//
//  CreateRoomController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 17.11.24.
//

import UIKit

class CreateRoomController: BaseController<CreateRoomView> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Room"
        self.navigationController?.navigationBar.tintColor = .black
        
        self.contentView.continueButton.addTarget(self, action: #selector(continueButtonClick), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @objc func continueButtonClick() {
        guard let roomName = self.contentView.roomNameTextField.text else { return }
        guard let roomType = self.contentView.selectedType else { return }
        
        let room = Room(name: roomName, type: roomType)
        let mainController = MainController.factoryController(room) as UIViewController
        
        let roomSelectionController: UIViewController = self.navigationController!.viewControllers[0]
        self.navigationController?.setViewControllers([roomSelectionController, mainController], animated: true)
    }
}


