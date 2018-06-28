//
//  CloudVolume.swift
//  WeatherOverground
//
//  Created by Jim Martin on 6/20/18.
//  Copyright © 2018 Avi Cieplinski. All rights reserved.
//

import Foundation
import SceneKit

class CloudVolume: SCNNode {
    
    override init() {
        super.init()
        setGeometry()
        setCloudShader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setGeometry()
        setCloudShader()
    }
    
    private func setGeometry(){
        
        self.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0)
        
    }
    
    private func setCloudShader(){
        
        //create cloud material
        let cloudMaterial = SCNMaterial()
        
//        //needed for in-volume cloud rendering
//        cloudMaterial.isDoubleSided = true;
        self.geometry?.firstMaterial = cloudMaterial
        
        
        //set shader program
        let program = SCNProgram()
        program.fragmentFunctionName = "cloudFragment"
        program.vertexFunctionName = "cloudVertex"
        program.isOpaque = false;
        cloudMaterial.program = program
        
        //set noise texture
        let noiseImage  = UIImage(named: "art.scnassets/PerlinFullRough.png")!
        let noiseImageProperty = SCNMaterialProperty(contents: noiseImage)
        cloudMaterial.setValue(noiseImageProperty, forKey: "noiseTexture")
        
        let intImage  = UIImage(named: "art.scnassets/PerlinFullSoft.png")!
        let intImageProperty = SCNMaterialProperty(contents: intImage)
        cloudMaterial.setValue(intImageProperty, forKey: "interferenceTexture")
        
        //set debug texture
        let image = UIImage(named: "art.scnassets/UV_Grid_Sm.png")!
        let imageProperty = SCNMaterialProperty(contents: image)
        cloudMaterial.setValue(imageProperty, forKey: "debugTexture")
    }
    
}
