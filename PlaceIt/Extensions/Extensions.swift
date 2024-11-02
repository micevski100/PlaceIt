//
//  ARKitExtensions.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import Foundation
import UIKit
import ARKit

// MARK: - CGPoint

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }

    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

// MARK: - float4x4

extension float4x4 {
    
    /// Transforms a matrix into float3.
    /// Gives the x, y, and z from the matrix.
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}

// MARK: - UIGestureRecognizer

/// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint? {
        guard numberOfTouches > 0 else { return nil }
        
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}

// MARK: - ARSCNView

extension ARSCNView {
    func virtualObject(at point: CGPoint) -> VirtualObject? {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap { result in
            return VirtualObject.existingObjectContainingNode(result.node)
        }.first
    }
}

extension SCNNode {
  func setCategoryBitMaskForAllHierarchy(_ highlightedBitMask: Int = 2,
                                         nodesToExclude: Set<String> = Set<String>()) {
    if let selfName = name {
      if !nodesToExclude.contains(selfName) {
        categoryBitMask = highlightedBitMask
      }
    }
    else {
      categoryBitMask = highlightedBitMask
    }
    
    for child in self.childNodes {
      child.setCategoryBitMaskForAllHierarchy(highlightedBitMask,
                                              nodesToExclude: nodesToExclude)
    }
  }
}

// MARK: - Dictionary

struct KeyPath {
  var segments: [String]
  
  var isEmpty: Bool { return segments.isEmpty }
  var path: String {
    return segments.joined(separator: ".")
  }
  
  /// Strips off the first segment and returns a pair
  /// consisting of the first segment and the remaining key path.
  /// Returns nil if the key path has no segments.
  func headAndTail() -> (head: String, tail: KeyPath)? {
    guard !isEmpty else { return nil }
    var tail = segments
    let head = tail.removeFirst()
    return (head, KeyPath(segments: tail))
  }
}


/// Initializes a KeyPath with a string of the form "this.is.a.keypath"
extension KeyPath {
  init(_ string: String) {
    segments = string.components(separatedBy: ".")
  }
}

extension KeyPath: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(value)
  }
  init(unicodeScalarLiteral value: String) {
    self.init(value)
  }
  init(extendedGraphemeClusterLiteral value: String) {
    self.init(value)
  }
}


// Needed because Swift 3.0 doesn't support extensions with concrete
// same-type requirements (extension Dictionary where Key == String).
protocol StringProtocol {
  init(string s: String)
}

extension String: StringProtocol {
  init(string s: String) {
    self = s
  }
}

extension Dictionary where Key: StringProtocol {
  subscript(keyPath keyPath: KeyPath) -> Any? {
    get {
      switch keyPath.headAndTail() {
      case nil:
        // key path is empty.
        return nil
      case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
        // Reached the end of the key path.
        let key = Key(string: head)
        return self[key]
      case let (head, remainingKeyPath)?:
        // Key path has a tail we need to traverse.
        let key = Key(string: head)
        switch self[key] {
        case let nestedDict as [Key: Any]:
          // Next nest level is a dictionary.
          // Start over with remaining key path.
          return nestedDict[keyPath: remainingKeyPath]
        default:
          // Next nest level isn't a dictionary.
          // Invalid key path, abort.
          return nil
        }
      }
    }
    set {
      switch keyPath.headAndTail() {
      case nil:
        // key path is empty.
        return
      case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
        // Reached the end of the key path.
        let key = Key(string: head)
        self[key] = newValue as? Value
      case let (head, remainingKeyPath)?:
        let key = Key(string: head)
        let value = self[key]
        switch value {
        case var nestedDict as [Key: Any]:
          // Key path has a tail we need to traverse
          nestedDict[keyPath: remainingKeyPath] = newValue
          self[key] = nestedDict as? Value
        default:
          // Invalid keyPath
          return
        }
      }
    }
  }
}

extension Dictionary where Key: StringProtocol {
  subscript(string keyPath: KeyPath) -> String? {
    get { return self[keyPath: keyPath] as? String }
    set { self[keyPath: keyPath] = newValue }
  }
  
  subscript(dict keyPath: KeyPath) -> [Key: Any]? {
    get { return self[keyPath: keyPath] as? [Key: Any] }
    set { self[keyPath: keyPath] = newValue }
  }
}

// MARK: - UIView

extension UIView {
    public var width: CGFloat {
        return self.frame.size.width
    }
    
    public var height: CGFloat {
        return self.frame.size.height
    }
}
