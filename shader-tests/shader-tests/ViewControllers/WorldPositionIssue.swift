//
//  WorldPositionIssue.swift
//  shader-tests
//
//  Created by Jim Martin on 7/3/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class WorldPositionIssue: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    private var scene: SCNScene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup scene
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.isPlaying = true
        scene.background.contents = UIColor.gray
        
        //setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        //setup light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = SCNLight.LightType.directional
        lightNode.light?.color = UIColor.white
        scene.rootNode.addChildNode(lightNode)
        
        
        //test node
        let node = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
        node.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(node)
        
        print("setup --- ")
        print("local position: \(node.position) | world position: \(node.worldPosition)") // (0,0,0), (0,0,0) expected
        
        
        node.pivot = SCNMatrix4MakeTranslation(10.0, 10.0, 10.0)
        
        print("after pivot --- ")
        print("local position: \(node.position) | world position: \(node.worldPosition)") // (0,0,0), (10,10,10) why are these different?
        
        node.scale = SCNVector3Make(0.5, 0.5, 0.5)
        
        print("after scale --- ")
        print("local position: \(node.position) | world position: \(node.worldPosition)") //(0,0,0), (10,10,10) but the cube geometry appears at (5,5,5)
        
    }
}

