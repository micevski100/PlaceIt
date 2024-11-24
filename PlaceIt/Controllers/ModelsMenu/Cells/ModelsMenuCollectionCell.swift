//
//  ModelsMenuCollectionCell.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 22.11.24.
//

import UIKit
import SnapKit

class ModelsMenuCollectionCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ModelsMenuCollectionCell"
    weak var controller: ModelsMenuController?
    
    var containerView: UIVisualEffectView!
    var titleLabel: UILabel!
    var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            guard let isSectioned = controller?.isSectionedController,
                  !isSectioned else { return }
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
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.contentView.backgroundColor = .clear
        
        let blurrEffect = UIBlurEffect(style: .light)
        containerView = UIVisualEffectView(effect: blurrEffect)
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        containerView.isUserInteractionEnabled = true
        self.contentView.addSubview(containerView)
        
        titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        containerView.contentView.addSubview(titleLabel)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        containerView.contentView.addSubview(imageView)
    }
    
    func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(containerView)
            make.left.right.equalTo(containerView).inset(10)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(containerView)
            make.bottom.equalTo(titleLabel.snp.top).offset(-5)
        }
    }
    
    func setup(_ title: String, _ thumbImage: UIImage? = nil) {
        self.titleLabel.text = title
        self.imageView.image = thumbImage
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        imageView.image = nil
    }
}
