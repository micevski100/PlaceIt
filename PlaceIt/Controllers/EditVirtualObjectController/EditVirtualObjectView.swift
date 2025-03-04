//
//  EditVirtualObjectView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 26.1.25.
//

import UIKit
import SnapKit

class EditVirtualObjectView: BaseView {
    
    var containerView: UIVisualEffectView!
    var titleLabel: UILabel!
    var closeButton: UIButton!
    var collectionView: UICollectionView!
    
    override func setupViews() {
        let blurrEffect = UIBlurEffect(style: .light)
        containerView = UIVisualEffectView(effect: blurrEffect)
        containerView.layer.masksToBounds = true
        self.addSubview(containerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Color"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        containerView.contentView.addSubview(titleLabel)
        
        closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "x.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        containerView.contentView.addSubview(closeButton)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        containerView.contentView.addSubview(collectionView)
    }
    
    override func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(10)
            make.width.height.equalTo(70)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(0.8))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
        group.interItemSpacing = .fixed(10)
        
        // Sections
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
