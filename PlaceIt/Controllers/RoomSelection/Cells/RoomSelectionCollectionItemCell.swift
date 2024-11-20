//
//  RoomSelectionCollectionItemCell.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 17.11.24.
//

import UIKit
import SnapKit

class RoomSelectionCollectionItemCell: UICollectionViewCell {
    
    static let identifier: String = "RoomSelectionCollectionItemCell"
    
    var item: Room!
    var delegate: RoomSelectionCollectionItemCellDelegate?
    
    var thumbnailImageView: UIImageView!
    var roomNameLabel: UILabel!
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
        self.backgroundColor = .clear
        
        thumbnailImageView = UIImageView()
        thumbnailImageView.backgroundColor = .red
        thumbnailImageView.layer.cornerRadius = 15
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        self.contentView.addSubview(thumbnailImageView)
        
        roomNameLabel = UILabel()
        roomNameLabel.text = "asdadas"
        roomNameLabel.numberOfLines = 1
        roomNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        roomNameLabel.textAlignment = .center
        self.addSubview(roomNameLabel)
        
        cellButton = UIButton()
        cellButton.addTarget(self, action: #selector(cellButtonClick), for: .touchUpInside)
        self.addSubview(cellButton)
    }
    
    func setupConstraints() {
        thumbnailImageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(roomNameLabel.snp.top)
        }
        
        roomNameLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }
        
        cellButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setup(_ item: Room) {
        self.item = item
        roomNameLabel.text = item.name
        thumbnailImageView.image = item.type.image
    }
    
    @objc func cellButtonClick() {
        self.delegate?.didSelectRoom(item)
    }
    
    override func prepareForReuse() {
        self.item = nil
        self.roomNameLabel.text = nil
        self.thumbnailImageView.image = nil
    }
}

protocol RoomSelectionCollectionItemCellDelegate {
    func didSelectRoom(_ room: Room)
}
