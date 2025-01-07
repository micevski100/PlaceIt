//
//  ShutterButton.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 6.1.25.
//

import UIKit

// TODO: Animate Inner View
class ShutterButton: UIButton {
    
    private var innerView: UIView!
    private var innerViewTopConstraint: NSLayoutConstraint!
    private var innerViewLeadingConstraint: NSLayoutConstraint!
    private var innerViewTrailingConstraint: NSLayoutConstraint!
    private var innerViewBottomConstraint: NSLayoutConstraint!
    
    private var snapShotImageView: UIImageView!
    
    
    required init() {
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        self.backgroundColor = .black
        self.layer.borderWidth = 4
        self.layer.borderColor = UIColor.white.cgColor
        
        innerView = UIView()
        innerView.translatesAutoresizingMaskIntoConstraints = false
        innerView.isUserInteractionEnabled = false
        innerView.backgroundColor = .white
        self.addSubview(innerView)
        
        let inset = 7.0
        innerViewTopConstraint = innerView.topAnchor.constraint(equalTo: self.topAnchor, constant: inset)
        innerViewLeadingConstraint = innerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: inset)
        innerViewTrailingConstraint = innerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -inset)
        innerViewBottomConstraint = innerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -inset)
        NSLayoutConstraint.activate([
            innerViewTopConstraint,
            innerViewLeadingConstraint,
            innerViewTrailingConstraint,
            innerViewBottomConstraint
        ])
        
//        let view = self.superview!
//        let snapshotImageView = UIImageView()
//        snapshotImageView.translatesAutoresizingMaskIntoConstraints = false
//        snapshotImageView.backgroundColor = .red
//        snapshotImageView.alpha = 0.0
//        view.addSubview(snapshotImageView)
//        
//        var leftConstraint = snapshotImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
//        var bottomConstraint = snapshotImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
//        var widthConstraint = snapshotImageView.widthAnchor.constraint(equalToConstant: view.frame.width - 20)
//        var heightConstraint = snapshotImageView.heightAnchor.constraint(equalToConstant: view.frame.height - 20)
//        NSLayoutConstraint.activate([
//            bottomConstraint,
//            leftConstraint,
//            widthConstraint,
//            heightConstraint
//        ])
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 80, height: 80)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        triggerFlashAnimation()
        triggerInnerViewInsetsAnimation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        self.innerView.layer.cornerRadius = self.innerView.frame.height / 2
    }
    
    private func triggerFlashAnimation() {
        guard let view = self.superview else { return }
        
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.2) {
            flashView.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                flashView.alpha = 0.0
            } completion: { _ in
                flashView.removeFromSuperview()
//                self.snapshotAnimation()
            }

        }
    }
    
    private func snapshotAnimation() {
        guard let view = self.superview else { return }
        
        let h = view.frame.height * 0.32
        let constat1 = view.frame.height - h
        
        let w = view.frame.width * 0.3
        let constant2 = view.frame.width - w
        
        
        
        
        UIView.animate(withDuration: 0.2) {
//            widthConstraint.constant = constant2
//            heightConstraint.constant = constat1
            self.snapShotImageView.alpha = 1
            
            view.layoutIfNeeded()
        } completion: { _ in
            
        }

    }
    
    private func triggerInnerViewInsetsAnimation() {
        let originalInset: CGFloat = 7.0
        let increasedInset: CGFloat = 15.0
        
        UIView.animate(withDuration: 0.2) {
            self.innerViewTopConstraint.constant = increasedInset
            self.innerViewLeadingConstraint.constant = increasedInset
            self.innerViewTrailingConstraint.constant = -increasedInset
            self.innerViewBottomConstraint.constant = -increasedInset
            
            self.layoutIfNeeded()
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.innerViewTopConstraint.constant = originalInset
                self.innerViewLeadingConstraint.constant = originalInset
                self.innerViewTrailingConstraint.constant = -originalInset
                self.innerViewBottomConstraint.constant = -originalInset
                
                self.layoutIfNeeded()
            }
        }
    }
}
