//
//  Test.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 13.12.24.
//

import UIKit

class Test: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let modelURL = Bundle.main.url(forResource: "Models.scnassets/Chairs/Bar Stool/Bar Stool", withExtension: "dae")!
        
        let object = VirtualObject(url: modelURL)
        
        let x = ModelsManager.shared.getTextures(for: object)
    }
}
