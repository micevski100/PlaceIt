//
//  MainView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import UIKit
import ARKit
import SnapKit
import TipKit

class MainView: BaseView {
    
    // MARK: - UI Elements
    var sceneView: ARView!
    var snapshotThumbnailImageView: UIImageView!
    var sessionInfoView: UIVisualEffectView! // TODO: Addd fade in animation.
    var sessionInfoLabel: UILabel!
//    var saveExperienceButton: UIButton!
    var shutterButton: ShutterButton!
    var showModelsMenuButton: UIButton!
    
    var tipView: TipUIView?
    var addModelTip = AddModelTip()
    
    var test: UIImageView = {
        let img = UIImageView()
        img.alpha = 0
        img.layer.cornerRadius = 10
        img.layer.borderWidth = 6
        img.layer.borderColor = UIColor.white.cgColor
        return img
    }()
    
    var testWidthConstraint: Constraint!
    var testHeightConstraint: Constraint!
    
    // MARK: - Layout
    override func setupViews() {
        sceneView = ARView(frame: .zero)
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        sceneView.showsStatistics = true
        sceneView.isUserInteractionEnabled = true
        sceneView.backgroundColor = .black
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.addSubview(sceneView)
        
        snapshotThumbnailImageView = UIImageView()
        snapshotThumbnailImageView.contentMode = .scaleAspectFill
        snapshotThumbnailImageView.clipsToBounds = true
        snapshotThumbnailImageView.layer.cornerRadius = 8
        snapshotThumbnailImageView.isHidden = true
        self.addSubview(snapshotThumbnailImageView)
        
        let blurEffect = UIBlurEffect(style: .light)
        sessionInfoView = UIVisualEffectView(effect: blurEffect)
        sessionInfoView.layer.masksToBounds = true
        sessionInfoView.layer.cornerRadius = 10
        self.addSubview(sessionInfoView)
        
        sessionInfoLabel = UILabel()
        sessionInfoLabel.font = UIFont.systemFont(ofSize: 17)
        sessionInfoLabel.textAlignment = .center
        sessionInfoLabel.numberOfLines = 3
        sessionInfoView.contentView.addSubview(sessionInfoLabel)
        
//        saveExperienceButton = UIButton()
//        saveExperienceButton.setTitle("Save Experience", for: .normal)
//        saveExperienceButton.setTitleColor(.white, for: [])
//        saveExperienceButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        saveExperienceButton.backgroundColor = .systemGreen
//        saveExperienceButton.layer.cornerRadius = 8
////        saveExperienceButton.isHidden = true
//        self.addSubview(saveExperienceButton)
        self.addSubview(test)
        
        shutterButton = ShutterButton()
        shutterButton.alpha = 0
        self.addSubview(shutterButton)
        
        showModelsMenuButton = UIButton()
        showModelsMenuButton.setImage(UIImage(named: "addButtonImage"), for: [])
        showModelsMenuButton.setImage(UIImage(named: "addButtonImagePressed"), for: .selected)
        self.addSubview(showModelsMenuButton)
    }
    
    override func setupConstraints() {
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        snapshotThumbnailImageView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide)
            make.left.equalTo(self.safeAreaLayoutGuide).offset(10)
            make.width.equalToSuperview().multipliedBy(0.32)
            make.height.equalToSuperview().multipliedBy(0.3)
        }
        
        sessionInfoView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
//            make.bottom.equalTo(saveExperienceButton.snp.top).offset(-15)
            make.bottom.equalTo(shutterButton.snp.top).offset(-15)
            make.width.lessThanOrEqualToSuperview().inset(20)
        }
        
        sessionInfoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        
//        saveExperienceButton.snp.makeConstraints { make in
//            make.centerX.equalToSuperview()
//            make.centerY.equalTo(showModelsMenuButton)
//            make.width.equalToSuperview().multipliedBy(0.5)
//            make.height.equalTo(40)
//        }
        
        shutterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(showModelsMenuButton)
        }
        
        showModelsMenuButton.snp.makeConstraints { make in
            make.bottom.right.equalTo(self.safeAreaLayoutGuide).inset(20)
            make.width.height.equalTo(60)
        }
        
        test.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.bottom.equalTo(shutterButton.snp.bottom)
            testWidthConstraint = make.width.equalToSuperview().offset(-40).constraint
            testHeightConstraint = make.height.equalTo(self).multipliedBy(0.89).constraint
            testWidthConstraint.activate()
            testHeightConstraint.activate()
        }
    }
    
    func testAnim(completion: @escaping (Bool) -> Void) {
        self.layoutIfNeeded()
        let targetWidth = self.width * 0.36
        let targetHeight = self.height * 0.33
        UIView.animate(withDuration: 0.9) {
            self.test.alpha = 1
            self.testWidthConstraint.update(inset: targetWidth)
            self.testHeightConstraint.update(inset: targetHeight)
            
            self.layoutIfNeeded()
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                UIView.animate(withDuration: 0.2) {
//                    self.test.alpha = 0
//                    self.shutterButton.alpha = 0
//                }
                UIView.animate(withDuration: 0.2, animations: {
                    self.test.alpha = 0
                    self.shutterButton.alpha = 0
                }, completion: completion)
            }
        }

    }
    
    func tryDisplayTip() {
        Task { @MainActor in
            for await shouldDisplay in addModelTip.shouldDisplayUpdates {
                guard shouldDisplay else {
                    tipView?.removeFromSuperview()
                    tipView = nil
                    continue
                }
                
                if (tipView != nil) {
                    continue
                }
                
                let tipHostingView = TipUIView(addModelTip)
                self.superview?.addSubview(tipHostingView)
                
                tipHostingView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview().inset(20)
                    make.bottom.equalToSuperview()
                }
                
                tipView = tipHostingView
            }
        }
    }
}
