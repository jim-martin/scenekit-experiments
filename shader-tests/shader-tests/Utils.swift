//
//  Utils.swift
//  WeatherOverground
//
//  Created by Jim Martin on 6/25/18.
//  Copyright © 2018 Avi Cieplinski. All rights reserved.
//

import Foundation
import SceneKit

// MARK: - threading

//add code block to background thread, usage:
// BG {
//    code
// }
public func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}
//add code block to main thread, usage:
// UI {
//    code
// }
public func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

//MARK: - scenekit extensions

//SCNMatrix4 -> float4x4
extension float4x4 {
    init(_ matrix: SCNMatrix4) {
        self.init([
            float4(matrix.m11, matrix.m12, matrix.m13, matrix.m14),
            float4(matrix.m21, matrix.m22, matrix.m23, matrix.m24),
            float4(matrix.m31, matrix.m32, matrix.m33, matrix.m34),
            float4(matrix.m41, matrix.m42, matrix.m43, matrix.m44)
            ])
    }
}

//SCNVector -> float4
extension float4 {
    init(_ vector: SCNVector4) {
        self.init(vector.x, vector.y, vector.z, vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(vector.x, vector.y, vector.z, 1)
    }
}

//float4 -> SCNVector4
extension SCNVector4 {
    init(_ vector: float4) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
    }
}

//float4 -> SCNVector3
extension SCNVector3 {
    init(_ vector: float4) {
        self.init(x: vector.x / vector.w, y: vector.y / vector.w, z: vector.z / vector.w)
    }
}

//SCNMatrix4 * SCNVector3
func * (left: SCNMatrix4, right: SCNVector3) -> SCNVector3 {
    let matrix = float4x4(left)
    let vector = float4(right)
    let result = matrix * vector
    
    return SCNVector3(result)
}
