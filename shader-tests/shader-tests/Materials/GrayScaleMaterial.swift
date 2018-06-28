//
//  GrayScaleMaterial.swift
//  learning-scenekit
//
//  Created by Jim Martin on 6/12/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

@objc
class GrayScaleMaterial : SCNMaterial
{
    
    //define the value observed in the shader (https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/KVO.html#//apple_ref/doc/uid/TP40008195-CH16)
    //Can't figure out how to get the objc types to work using the above link ^
    
    //define a setter that sets the shader value when the public mixlevel is updated
        private var _mixLevel: Float! = 0.0
        var mixLevel : Float! {
            get{ return _mixLevel }
            set(newMixLevel){
                _mixLevel = newMixLevel
                setValue(_mixLevel, forKey: "_mixLevel")
            }
        }
    
    //    @objc dynamic var mixLevel : NSNumber!
    
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
        let grayScaleFragmentModifier : String? = """
                        _output.color.rgb = 1.0 - _output.color.rgb;
                        """
        
        //assign the fragment shader modifier
        var modifiers = [SCNShaderModifierEntryPoint : String]()
        modifiers[SCNShaderModifierEntryPoint.fragment] = grayScaleFragmentModifier
        self.shaderModifiers = modifiers
        
        //        mixLevel = 1.0 as NSNumber
    }
    
    
}
