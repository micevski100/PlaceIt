//
//  UIDropdown.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 19.11.24.
//

import UIKit
import SnapKit

// TODO: - Not implemented

// MARK: - Version 1
class UIDropdown<T: CustomStringConvertible>: UIView, UITableViewDelegate, UITableViewDataSource {
    
    private let data: [T]
    private(set) var selectedType: T? {
        didSet {
            placeHolderLabel.text = selectedType?.description
        }
    }
    private(set) var isDropDownOpen: Bool = false {
        didSet {
            self.tableHeightConstraint.update(offset: isDropDownOpen ? 200 : 50)
            self.placeHolderLabel.isHidden = isDropDownOpen
            self.tableView.isHidden = !isDropDownOpen
            print(tableView.frame)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.layoutIfNeeded()
            }) { _ in
                print(self.tableView.frame)
            }
        }
    }
    
    var placeHolderLabel: UILabel!
    var tableView: UITableView!
    var tableHeightConstraint: Constraint!
    
    required init(data: [T]) {
        self.data = data
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        placeHolderLabel = UILabel()
        placeHolderLabel.text = "Select Room Type"
        placeHolderLabel.font = UIFont.systemFont(ofSize: 16)
        placeHolderLabel.textAlignment = .center
        placeHolderLabel.isUserInteractionEnabled = true
        placeHolderLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(placeHolderTap)))
        self.addSubview(placeHolderLabel)
        
        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 15
        tableView.isHidden = true
        self.addSubview(tableView)
    }
    
    func setupConstraints() {
        placeHolderLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            tableHeightConstraint = make.height.equalTo(50).constraint
            tableHeightConstraint.isActive = true
        }
        
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(50)
        }
    }
    
    @objc func placeHolderTap() {
        print("ey2")
        isDropDownOpen.toggle()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = data[indexPath.row].description
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("eyy")
        selectedType = data[indexPath.row]
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        isDropDownOpen.toggle()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - Version 2

class DropdownButton: UIButton, DropdownDelegate {
    func dropdownPressed(string: String) {
         self.setTitle(string, for: .normal)
        self.dismissDropdown()
    }
    
    func dismissDropdown() {
        isOpen = false
        dropdownViewHeight.update(offset: 0)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.dropView.center.y -= self.dropView.frame.height / 2
            self.dropView.layoutIfNeeded()
        })
    }
    
    var dropView: DropdownView!
    var dropdownViewHeight: Constraint!
    var isOpen = false
    
    required init() {
        super.init(frame: .zero)
        
        dropView = DropdownView()
        dropView.delegate = self
        
        dropView.backgroundColor = self.backgroundColor
        dropView.layer.cornerRadius = self.layer.cornerRadius
        dropView.layer.borderWidth = self.layer.borderWidth
        dropView.layer.borderColor = self.layer.borderColor
        dropView.layer.shadowRadius = self.layer.shadowRadius
        dropView.layer.shadowOffset = self.layer.shadowOffset
        dropView.layer.shadowColor = self.layer.shadowColor
        dropView.layer.shadowOpacity = self.layer.shadowOpacity
        dropView.layer.shadowPath = self.layer.shadowPath
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubviewToFront(dropView)
        
        dropView.snp.makeConstraints { make in
            make.top.equalTo(self.snp.bottom)
            make.centerX.equalTo(self.snp.centerX)
            make.width.equalTo(self.snp.width)
            dropdownViewHeight = make.height.equalTo(0).constraint
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isOpen {
            isOpen = true
            if self.dropView.tableView.contentSize.height > 150 {
                dropdownViewHeight.update(offset: 150)
            } else {
                dropdownViewHeight.update(offset: self.dropView.tableView.contentSize.height)
            }
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            })
        } else {
            dismissDropdown()
        }
    }
}

class DropdownView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var dropdownOptions: [String] = ["1", "2", "3", "4", "5"]
    
    var delegate: DropdownDelegate!
    
    var tableView: UITableView!
    
    required init() {
        super.init(frame: .zero)
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropdownOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = dropdownOptions[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.dropdownPressed(string: dropdownOptions[indexPath.row])
    }
}

protocol DropdownDelegate {
    func dropdownPressed(string: String)
}
