//
//  SliceVolume.swift
//  shader-tests
//
//  Created by Jim Martin on 6/29/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class SliceVolume: SCNNode, SCNNodeRendererDelegate{
    
    override init() {
        super.init()
        setGeometry()
        setShader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setGeometry()
        setShader()
    }
    
    private func setGeometry(){
        
        self.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0)
        
    }
    
    private func setShader(){
        
        //create material
        let material = SCNMaterial()
        
        //        //needed for in-volume cloud rendering
        //        cloudMaterial.isDoubleSided = true;
        self.geometry?.firstMaterial = material
        
        
        //set shader program
        let program = SCNProgram()
        program.fragmentFunctionName = "sliceFragment"
        program.vertexFunctionName = "sliceVertex"
        program.isOpaque = false;
        material.program = program
        
        //set noise texture
        let noiseImage  = UIImage(named: "art.scnassets/UV_Grid_Sm.png")!
        let noiseImageProperty = SCNMaterialProperty(contents: noiseImage)
        material.setValue(noiseImageProperty, forKey: "diffuseTexture")
        
    }
    
}
