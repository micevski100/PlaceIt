//
//  Test.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 6.1.25.
//

import UIKit
import SnapKit


class Test: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        
        let shutterButton = ShutterButton()
        shutterButton.addTarget(self, action: #selector(takeScreenShot), for: .touchUpInside)
        self.view.addSubview(shutterButton)
        
        shutterButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
        }
        
        self.navigationController?.pushViewController( MainController.factoryController(.init(name: "asad", type: .bathRoom)), animated: true)
    }
    
    @objc func takeScreenShot() {
        captureScreenshotWithAnimation()
    }
    
    func captureScreenshotWithAnimation() {
       print("taking screenshot")
    }

}
