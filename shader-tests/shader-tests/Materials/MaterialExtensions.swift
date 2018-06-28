//
//  MaterialExtensions.swift
//  learning-scenekit
//
//  Created by Jim Martin on 6/13/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

extension SCNMaterial {
    
    public func applyShaderModifier( shader: ShaderData ){
        
        if self.shaderModifiers == nil {
            self.shaderModifiers = [SCNShaderModifierEntryPoint : String]()
        }
        
        self.shaderModifiers![shader.entryPoint] = shader.shaderProgram
        
    }
    
    convenience init( shader: ShaderData ){
        self.init()
        applyShaderModifier(shader: shader)
    }
    
}
