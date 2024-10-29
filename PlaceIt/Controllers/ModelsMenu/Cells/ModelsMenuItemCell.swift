//
//  ModelsMenuItemCell.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 26.10.24.
//

import UIKit
import SnapKit

class ModelsMenuItemCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "VirtualObjectSelectionCollectionItemCell"
    
    var modelName = "" {
        didSet {
            modelNameLabel.text = modelName
//            modelImageView.image = UIImage(named: modelName)
            modelImageView.image = UIImage(named: "chair")
        }
    }
    
    override var isSelected: Bool {
        didSet{
            if self.isSelected {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
                }
            }
            else {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.backgroundColor = .clear
                }
            }
        }
    }
    
    // MARK: - UI Elements
    
    var containerView: UIVisualEffectView!
    var modelNameLabel: UILabel!
    var modelImageView: UIImageView!
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    func setupViews() {
        self.contentView.backgroundColor = .clear
        
        let blurrEffect = UIBlurEffect(style: .light)
        containerView = UIVisualEffectView(effect: blurrEffect)
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        containerView.isUserInteractionEnabled = true
        self.contentView.addSubview(containerView)
        
        modelImageView = UIImageView()
        modelImageView.contentMode = .scaleAspectFit
        modelImageView.clipsToBounds = true
        containerView.contentView.addSubview(modelImageView)
        
        modelNameLabel = UILabel()
        modelNameLabel.numberOfLines = 2
        modelNameLabel.textAlignment = .center
        modelNameLabel.adjustsFontSizeToFitWidth = true
        containerView.contentView.addSubview(modelNameLabel)
    }
    
    func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        modelImageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(containerView)
            make.bottom.equalTo(modelNameLabel.snp.top)
        }
        
        modelNameLabel.snp.makeConstraints { make in
            make.bottom.equalTo(containerView)
            make.left.right.equalTo(containerView).inset(10)
        }
    }
    
    func setup(_ modelName: String) {
        self.modelName = modelName
    }
    
    override func prepareForReuse() {
        self.modelName = ""
        self.modelNameLabel.text = ""
        self.modelImageView.image = nil
    }
}
