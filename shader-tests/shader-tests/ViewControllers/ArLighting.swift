//
//  ArLighting.swift
//  shader-tests
//
//  Created by Jim Martin on 7/3/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class ArLighting: UIViewController, ARSCNViewDelegate {
    
    //scene and AR setup
    @IBOutlet var sceneView: ARSCNView!
    var scene: SCNScene!
    var configuration: ARWorldTrackingConfiguration!
    
    //test lighting with this node
    var node: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup scene
        sceneView.delegate = self
        sceneView.showsStatistics = true
        scene = SCNScene()
        sceneView.scene = scene
        
        //setup AR lighting
        //with config
        configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true;
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        } else {
            // Fallback on earlier versions
        }
        //in scene
        sceneView.autoenablesDefaultLighting = true;
        sceneView.automaticallyUpdatesLighting = true;
        
        let background = UIImage(named: "art.scnassets/UV_Grid_Sm.png")
        scene.lightingEnvironment.contents =   [background, background, background, background, background, background]
        scene.lightingEnvironment.intensity = 10.0
        
        //setup test node
        node = SCNNode(geometry: SCNSphere(radius: 0.1))
        node.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(node)
        
        //setup node coloring
        let material = node.geometry?.firstMaterial
        material?.lightingModel = .physicallyBased
        material?.diffuse.contents = UIColor.white
        material?.roughness.contents = UIColor.black
        material?.metalness.contents = UIColor.white
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ gesture: UIGestureRecognizer) {
        
        //move the test node on tap
        let results = sceneView.hitTest(gesture.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitFeature = results.last else { return }
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,
                                         hitTransform.m42,
                                         hitTransform.m43)
        node.position = hitPosition;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //start AR session 
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //pause AR session
        sceneView.session.pause()
    }
}



