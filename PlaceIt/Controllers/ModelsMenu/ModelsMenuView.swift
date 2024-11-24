//
//  ModelsMenuView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 22.11.24.
//

import UIKit
import SnapKit

class ModelsMenuView: BaseView {
    
    // MARK: - UI Elements
    
    var containerView: UIVisualEffectView!
    var collectionView: UICollectionView!
    
    // MARK: - Layout
    
    override func setupViews() {
        self.backgroundColor = .clear
        
        containerView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        self.addSubview(containerView)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        containerView.contentView.addSubview(collectionView)
       
    }
    
    override func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(120))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
        group.interItemSpacing = .fixed(10)
        
        // Sections
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
