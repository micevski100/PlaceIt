//
//  RoomSelectionCollectionAddItemCell.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 17.11.24.
//

import UIKit
import SnapKit

class RoomSelectionCollectionAddItemCell: UICollectionViewCell {
    
    static let identifier = "RoomSelectionCollectionAddItemCell"
    
    var delegate: RoomSelectionCollectionAddItemCellDelegate?
    
    var thumbnailImageView: UIImageView!
    var plusSignImageView: UIImageView!
    var cellButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        thumbnailImageView = UIImageView()
        thumbnailImageView.image = UIImage(named: "defaultRoom")
        thumbnailImageView.backgroundColor = .red
        thumbnailImageView.layer.cornerRadius = 15
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        self.contentView.addSubview(thumbnailImageView)
        
        plusSignImageView = UIImageView(image: UIImage(named: "addButtonImage"))
        plusSignImageView.contentMode = .scaleAspectFit
        plusSignImageView.clipsToBounds = true
        self.contentView.addSubview(plusSignImageView)
        
        cellButton = UIButton()
        cellButton.addTarget(self, action: #selector(cellButtonClick), for: .touchUpInside)
        self.addSubview(cellButton)
    }
    
    func setupConstraints() {
        plusSignImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        cellButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func cellButtonClick() {
        self.delegate?.addRoom()
    }
}


protocol RoomSelectionCollectionAddItemCellDelegate {
    func addRoom()
}
