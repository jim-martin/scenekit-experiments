//
//  ClipMaterial.swift
//  learning-scenekit
//
//  Created by Jim Martin on 6/12/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

@objc
class ClipMaterial : SCNMaterial
{
    //shader vars
    public var clippingBox : SCNBox!
    
    //setters
    
    override init() {
        super.init()
        initShader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initShader() {
        
        //blends pixels toward grayscale using the mixLevel uniform
        //this should be loaded from a shader file
        let clippingShaderModifier : String? = """
                        _output.color.rgb = 1.0 - _output.color.rgb
                        """
        
        //assign the fragment shader modifier
        var modifiers = [SCNShaderModifierEntryPoint : String]()
        modifiers[SCNShaderModifierEntryPoint.fragment] = clippingShaderModifier
        self.shaderModifiers = modifiers
        
        //        mixLevel = 1.0 as NSNumber
    }
    
}
