//
//  VirtualObjectActionPanel.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 1.12.24.
//

import Foundation
import ARKit
import SceneKit

class VirtualObjectActionPanel: SCNNode {
    
    let actions: [Any]
    
    
    static let defaultActions: [Any] = [
        UIImage(systemName: "document.on.document.fill")!,
        UIImage(systemName: "trash.fill")!
    ]
    
    required init(actions: [Any] = VirtualObjectActionPanel.defaultActions) {
        self.actions = actions
        super.init()
        
        setup(with: actions)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func generateBlurredImage(size: CGSize, style: UIBlurEffect.Style) -> UIImage? {
        // Create a UIView with a blur effect
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(origin: .zero, size: size)
        
        // Render the view into an image
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        blurView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func setup(with actions: [Any]) {
        let n = CGFloat(actions.count)
        let padding = 0.03
        let pixelsPerUnit: CGFloat = 500
        
        let btnWidth = 0.08
        let btnHeight = 0.08
        
        let containerWidth = n * btnWidth + (n + 1) * padding
        let containerHeight = btnHeight + 2 * padding
        
        let imageWidth = containerWidth * pixelsPerUnit
        let imageHeight = containerHeight * pixelsPerUnit
        
        guard let blurredImage = generateBlurredImage(size: CGSize(width: imageWidth, height: imageHeight), style: .light) else { return }
        
        let containerGeometry = SCNPlane(width: containerWidth, height: containerHeight)
        containerGeometry.firstMaterial?.diffuse.contents = blurredImage
        containerGeometry.cornerRadius = containerHeight / 2
        
        self.geometry = containerGeometry
        
        
        for i in 0..<actions.count {
            let xLeft = (-containerWidth / 2) + (btnWidth / 2)
            let x = xLeft + CGFloat(i + 1) * padding + CGFloat(i) * btnWidth
            
            
            let btnGeometry = SCNPlane(width: btnWidth, height: btnHeight)
            btnGeometry.firstMaterial?.diffuse.contents = actions[i]
            btnGeometry.cornerRadius = btnHeight / 2
            
            let btnNode = SCNNode(geometry: btnGeometry)
            btnNode.name = "\(i)"
            btnNode.position = SCNVector3(x, 0, 0.01)
            
            self.addChildNode(btnNode)
        }
        
        let billboardConstraint = SCNBillboardConstraint()
        self.constraints = [billboardConstraint]
    }
    
    func addAppearAnimation(from position: SCNVector3) {
        let startPosition = SCNVector3(position.x, position.y - 0.05, position.z)
        
        self.opacity = 0
        self.position = startPosition
        
        let moveUpAnimation = CABasicAnimation(keyPath: "position")
        moveUpAnimation.fromValue = NSValue(scnVector3: startPosition)
        moveUpAnimation.toValue = NSValue(scnVector3: position)
        moveUpAnimation.duration = 0.5
        moveUpAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0
        fadeInAnimation.toValue = 1
        fadeInAnimation.duration = 0.5
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [moveUpAnimation, fadeInAnimation]
        groupAnimation.duration = 0.5
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        self.addAnimation(moveUpAnimation, forKey: "appearAnimation")
        
        self.opacity = 1
        self.position = position
    }
}
