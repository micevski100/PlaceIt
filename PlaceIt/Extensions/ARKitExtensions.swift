//
//  ARKitExtensions.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 24.10.24.
//

import Foundation
import ARKit

extension float4x4 {
    
    /// Transforms a matrix into float3.
    /// Gives the x, y, and z from the matrix.
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}
