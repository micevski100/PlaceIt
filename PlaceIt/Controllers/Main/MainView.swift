//
//  MainView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import UIKit
import ARKit
import SnapKit

class MainView: BaseView {
    
    // MARK: - UI Elements
    var sceneView: ARSCNView!
    var snapshotThumbnailImageView: UIImageView!
    var sessionInfoView: UIVisualEffectView! // TODO: Addd fade in animation.
    var sessionInfoLabel: UILabel!
    var saveExperienceButton: UIButton!
    var loadExperienceButton: UIButton!
    var showModelsMenuButton: UIButton!
    
    // MARK: - Layout
    override func setupViews() {
        
        sceneView = ARSCNView()
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        sceneView.showsStatistics = true
        sceneView.isUserInteractionEnabled = true
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
        sessionInfoView.layer.cornerRadius = 8
        self.addSubview(sessionInfoView)
        
        sessionInfoLabel = UILabel()
        sessionInfoLabel.text = "Some really long dummy text to check and see if the word wrapping is working like expected and is not breaking the UI. Adding some more text asdasdsa"
        sessionInfoLabel.font = UIFont.systemFont(ofSize: 17)
        sessionInfoLabel.textAlignment = .center
        sessionInfoLabel.numberOfLines = 3
        sessionInfoView.contentView.addSubview(sessionInfoLabel)
        
        saveExperienceButton = UIButton()
        saveExperienceButton.setTitle("Save Experience", for: .normal)
        saveExperienceButton.setTitleColor(.white, for: [])
        saveExperienceButton.titleLabel?.adjustsFontSizeToFitWidth = true
        saveExperienceButton.backgroundColor = .systemGreen
        saveExperienceButton.layer.cornerRadius = 8
        saveExperienceButton.isHidden = true
        self.addSubview(saveExperienceButton)
        
        loadExperienceButton = UIButton()
        loadExperienceButton.setTitle("Load Experience", for: .normal)
        loadExperienceButton.setTitleColor(.white, for: [])
        loadExperienceButton.titleLabel?.adjustsFontSizeToFitWidth = true
        loadExperienceButton.backgroundColor = .systemGray
        loadExperienceButton.isEnabled = false
        loadExperienceButton.layer.cornerRadius = 8
        loadExperienceButton.isHidden = true
        self.addSubview(loadExperienceButton)
        
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
            make.top.left.equalTo(self.safeAreaLayoutGuide).offset(10)
            make.width.equalToSuperview().multipliedBy(0.32)
            make.height.equalToSuperview().multipliedBy(0.3)
        }
        
        sessionInfoView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(saveExperienceButton.snp.top).offset(-15)
            make.width.lessThanOrEqualToSuperview().inset(20)
        }
        
        sessionInfoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        
        saveExperienceButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.right.equalTo(showModelsMenuButton.snp.left)
            make.centerY.equalTo(showModelsMenuButton)
            make.height.equalTo(40)
            make.width.equalToSuperview().multipliedBy(0.3)
        }
        
        loadExperienceButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalTo(showModelsMenuButton)
            make.height.equalTo(40)
            make.width.equalToSuperview().multipliedBy(0.3)
        }
        
        showModelsMenuButton.snp.makeConstraints { make in
            make.bottom.right.equalTo(self.safeAreaLayoutGuide).inset(20)
            make.width.height.equalTo(60)
        }
    }
}
