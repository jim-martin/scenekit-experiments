//
//  ShaderData.swift
//  learning-scenekit
//
//  Created by Jim Martin on 6/13/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import SceneKit

public class ShaderData: NSObject {
    
    var filename: String
    var shaderProgram: String
    var entryPoint: SCNShaderModifierEntryPoint
    
    private var ShaderDataExtension = [SCNShaderModifierEntryPoint.geometry : "gsm",
                                      SCNShaderModifierEntryPoint.surface : "ssm",
                                      SCNShaderModifierEntryPoint.lightingModel : "lsm",
                                      SCNShaderModifierEntryPoint.fragment : "fsm"]
    
    init(filename: String, entryPoint: SCNShaderModifierEntryPoint){
        self.filename = filename
        self.entryPoint = entryPoint
        
        let path = Bundle.main.path(forResource: self.filename, ofType: ShaderDataExtension[entryPoint])
        shaderProgram = try! String(contentsOfFile: path!, encoding: String.Encoding.utf8)
    }
}
