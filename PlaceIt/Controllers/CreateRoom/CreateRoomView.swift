//
//  CreateRoomView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 17.11.24.
//

import UIKit
import SnapKit

class CreateRoomView: BaseView {
    
    var isDropDownOpen: Bool = false {
        didSet {
            self.tableHeightConstraint.update(offset: isDropDownOpen ? 200 : 50)
            self.selectedDropdownLabel.isHidden = isDropDownOpen
            self.roomTypeDropDownTableView.isHidden = !isDropDownOpen
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    var selectedType: RoomType? = nil {
        didSet {
            selectedDropdownLabel.text = selectedType?.rawValue
        }
    }
    
    var container: UIView!
    var roomNameLabel: UILabel!
    var roomNameTextField: UITextField!
    
    var dropdownContainerView: UIView!
    var roomTypeLabel: UILabel!
    var roomTypeDropDownTableView: UITableView!
    var selectedDropdownLabel: UILabel!
    var tableHeightConstraint: Constraint!
    var continueButton: UIButton!
    
    override func setupViews() {
        self.backgroundColor = UIColor.init(hex: 0xF8F9FC)
        
        roomNameLabel = UILabel()
        roomNameLabel.text = "Room Name"
        roomNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        self.addSubview(roomNameLabel)
        
        roomNameTextField = UITextField()
        roomNameTextField.placeholder = "Enter room name"
        roomNameTextField.delegate = self
        roomNameTextField.returnKeyType = .default
        roomNameTextField.setLeftPaddingPoints(15)
        roomNameTextField.setRightPaddingPoints(15)
        roomNameTextField.backgroundColor = .white
        roomNameTextField.layer.cornerRadius = 15
        roomNameTextField.layer.borderWidth = 1
        roomNameTextField.layer.borderColor = UIColor.init(hex: 0xF3F7F9).cgColor
        roomNameTextField.backgroundColor = UIColor.white
        roomNameTextField.layer.shadowRadius = 1
        roomNameTextField.layer.shadowOffset = .init(width: 0, height: 1)
        roomNameTextField.layer.shadowColor = UIColor.init(hex: 0x5E799E).cgColor
        roomNameTextField.layer.shadowOpacity = 0.3
        roomNameTextField.clipsToBounds = false
        self.addSubview(roomNameTextField)
        
        roomTypeLabel = UILabel()
        roomTypeLabel.text = "Room Type"
        roomTypeLabel.font = UIFont.boldSystemFont(ofSize: 18)
        self.addSubview(roomTypeLabel)
        
        dropdownContainerView = UIView()
        dropdownContainerView.backgroundColor = .white
        dropdownContainerView.layer.cornerRadius = 15
        dropdownContainerView.layer.borderWidth = 1
        dropdownContainerView.layer.borderColor = UIColor.init(hex: 0xF3F7F9).cgColor
        dropdownContainerView.backgroundColor = UIColor.white
        dropdownContainerView.layer.shadowRadius = 1
        dropdownContainerView.layer.shadowOffset = .init(width: 0, height: 1)
        dropdownContainerView.layer.shadowColor = UIColor.init(hex: 0x5E799E).cgColor
        dropdownContainerView.layer.shadowOpacity = 0.3
        dropdownContainerView.clipsToBounds = false
        dropdownContainerView.layer.masksToBounds = false
        self.addSubview(dropdownContainerView)
        
        selectedDropdownLabel = UILabel()
        selectedDropdownLabel.text = "Select Room Type"
        selectedDropdownLabel.font = UIFont.systemFont(ofSize: 16)
        selectedDropdownLabel.textAlignment = .center
        selectedDropdownLabel.isUserInteractionEnabled = true
        selectedDropdownLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dropdownLabelTapped)))
        dropdownContainerView.addSubview(selectedDropdownLabel)
        
        roomTypeDropDownTableView = UITableView()
        roomTypeDropDownTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        roomTypeDropDownTableView.delegate = self
        roomTypeDropDownTableView.dataSource = self
        roomTypeDropDownTableView.clipsToBounds = true
        roomTypeDropDownTableView.layer.cornerRadius = 15
        roomTypeDropDownTableView.isHidden = true
        dropdownContainerView.addSubview(roomTypeDropDownTableView)
        
        continueButton = UIButton()
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        continueButton.layer.cornerRadius = 15
        continueButton.layer.shadowRadius = 3
        continueButton.layer.shadowOffset = .init(width: 0, height: 1)
        continueButton.layer.shadowColor = UIColor.init(hex: 0x5E799E).cgColor
        continueButton.layer.shadowOpacity = 0.3
        disableContinueButton()
        self.addSubview(continueButton)
    }
    
    func enableContinueButton() {
        continueButton.backgroundColor = .systemGreen
        continueButton.isEnabled = true
    }
    
    func disableContinueButton() {
        continueButton.backgroundColor = .lightGray.withAlphaComponent(0.5)
        continueButton.isEnabled = false
    }
    
    override func setupConstraints() {
        roomNameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().multipliedBy(0.8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        roomNameTextField.snp.makeConstraints { make in
            make.top.equalTo(roomNameLabel.snp.bottom).offset(5)
            make.left.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        roomTypeLabel.snp.makeConstraints { make in
            make.top.equalTo(roomNameTextField.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        dropdownContainerView.snp.makeConstraints { make in
            make.top.equalTo(roomTypeLabel.snp.bottom).offset(5)
            make.left.right.equalToSuperview().inset(20)
        }
        
        selectedDropdownLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        
        roomTypeDropDownTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            tableHeightConstraint = make.height.equalTo(50).constraint
            tableHeightConstraint.isActive = true
        }
        
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-10)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
//            make.bottom.equalToSuperview()
        }
        
        self.bringSubviewToFront(dropdownContainerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        continueButton.layer.cornerRadius = continueButton.height / 2
    }
    
    @objc func dropdownLabelTapped() {
        isDropDownOpen.toggle()
    }
}

extension CreateRoomView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return RoomType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textAlignment = .center
        
        cell.textLabel?.text = RoomType.allCases[indexPath.row].rawValue

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedType = RoomType.allCases[indexPath.row]
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        isDropDownOpen.toggle()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}


extension CreateRoomView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        
        if newString.count >= 5 {
            enableContinueButton()
        } else {
            disableContinueButton()
        }
        
        return newString.count <= 20
    }
}
