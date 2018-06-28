//
//  ViewController.swift
//  learning-scenekit
//
//  Created by Jim Martin on 6/11/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    private var scene: SCNScene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.isPlaying = true

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = SCNLight.LightType.directional
        lightNode.light?.color = UIColor.white
//        lightNode.light?.castsShadow = true;
        lightNode.light?.shadowMode = SCNShadowMode.deferred;
        lightNode.light?.shadowMapSize = CGSize(width: 1000, height: 1000)
        lightNode.light?.maximumShadowDistance = 20.0;
        
        //rotate light source
        lightNode.eulerAngles = SCNVector3(-0.8, 0.5, -0.5)

        scene.rootNode.addChildNode(lightNode)
        
        let environment = UIImage(named: "art.scnassets/UV_Grid_Sm.png")
        scene.lightingEnvironment.contents = environment
        scene.lightingEnvironment.intensity = 2.0
        
        let background = UIImage(named: "art.scnassets/UV_Grid_Sm.png")
        scene.background.contents = [background, background, background, background, background, background];
        
        let cloudNode = CloudVolume();
        scene.rootNode.addChildNode(cloudNode)
        cloudNode.scale = SCNVector3Make(3, 0.4, 3)
        
        let occlusionNode: SCNNode = SCNNode(geometry: SCNBox(width: 3, height: 0.2, length: 3, chamferRadius: 0));
        scene.rootNode.addChildNode(occlusionNode);
        occlusionNode.position.y -= 0.3;
        
        let shadowNode: SCNNode = SCNNode(geometry: SCNBox(width: 1, height: 0.2, length: 1, chamferRadius: 0));
        scene.rootNode.addChildNode(shadowNode);
        shadowNode.castsShadow = true;
        shadowNode.position.y += 0.3;
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}

