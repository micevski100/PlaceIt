//
//  BaseView.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import UIKit
import SnapKit

open class BaseView: UIView {
    
    open var shouldSetupConstraints = true
    open var viewController: UIViewController!
    
    public override required init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    open func setupViews() {}
    open func setupConstraints() {}
    open func setViewController(_ controller: UIViewController) {
        self.viewController = controller
    }
    
    open override func updateConstraints() {
        if shouldSetupConstraints {
            setupConstraints()
            self.shouldSetupConstraints = false
        }
        
        super.updateConstraints()
    }
    
    open class func factoryView() -> BaseView {
        return self.init(frame: CGRect.zero)
    }
}

