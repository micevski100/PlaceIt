//
//  UIFullLoadingController.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 29.12.24.
//

import UIKit
import SnapKit

class UIFullLoadingController: UIViewController {
    
    var blurEffectView: UIVisualEffectView!
    var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.8
        // Setting the autoresizing mask to flexible for
        // width and height will ensure the blurEffectView
        // is the same size as its parent view.
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        blurEffectView.frame = self.view.bounds
        self.view.addSubview(blurEffectView)
        
        
        logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "logo-compact")
        blurEffectView.contentView.addSubview(logoImageView)
        
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(UIScreen.main.bounds.width * 0.15)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doAnimation()
    }
    
    func doAnimation () {
        let spinAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        spinAnimation.fromValue = 0
        spinAnimation.toValue = CGFloat.pi * 2
        spinAnimation.duration = 1.5
        spinAnimation.repeatCount = .infinity
       
        logoImageView.layer.add(spinAnimation, forKey: "horizontalSpin")
    }
}
