//
//  ThresholdPanGesture.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 2.11.24.
//

import UIKit.UIGestureRecognizerSubclass

/// A custom `UIPanGestureRecognizer` to track when a translation threshold
/// has been esceeded and panning should begin.
class ThresholdPanGesture: UIPanGestureRecognizer {
    
    /// Indicates when the gesture's `state` changes to reset the threshold.
    private(set) var isThresholdExceeded = false
    
    /// Observe when the gesture's `state` changes to reset the threshold.
    override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
            default:
                // Reset threshold check.
                isThresholdExceeded = false
            }
        }
    }
    
    /// Returns the threshold value that should be used dependent on the number of touches.
    private static func threshold(forTouchCount count: Int) -> CGFloat {
        switch count {
        case 1:return 30
        
        // Use a higher threshold for gestures using more than 1 finger.
        // This gives other gestures priority.
        default: return 60
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        let translationMagnitude = translation(in: view).length
        
        // Adjust the threshold based on the number of touches being used.
        let threshold = ThresholdPanGesture.threshold(forTouchCount: touches.count)
        
        if !isThresholdExceeded && translationMagnitude > threshold {
            isThresholdExceeded = true
            
            // Set the overall translation to zero as the gesture should now begin.
            setTranslation(.zero, in: view)
        }
    }
}
