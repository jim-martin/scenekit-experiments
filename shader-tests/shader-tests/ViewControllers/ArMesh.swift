//
//  ArMesh.swift
//  shader-tests
//
//  Created by Jim Martin on 7/9/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class ArMesh: UIViewController {
    
    //scene and AR setup
    @IBOutlet var sceneView: ARSCNView!
    var scene: SCNScene!
    var configuration: ARWorldTrackingConfiguration!
    var planeId: Int = 0
    
    //hittest node
    var node: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup scene
        sceneView.showsStatistics = true
        scene = SCNScene()
        sceneView.scene = scene
        let background = UIImage(named: "art.scnassets/UV_Grid_Sm.png")
        scene.lightingEnvironment.contents =   [background, background, background, background, background, background]
        scene.lightingEnvironment.intensity = 10.0
        
        //setup AR
        setupArSession()
        
        //setup hittest node
        node = SCNNode(geometry: SCNSphere(radius: 0.05))
        scene.rootNode.addChildNode(node)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ gesture: UIGestureRecognizer) {
        
       //find the hit position in the scene
        let results = sceneView.hitTest(gesture.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitFeature = results.last else { return }
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,
                                         hitTransform.m42,
                                         hitTransform.m43)
        
        //do something with the hit position
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

extension SCNNode {
    
    @available(iOS 11.3, *)
    static func createPlaneNode(planeAnchor: ARPlaneAnchor, id: Int) -> SCNNode {
        let scenePlaneGeometry = ARSCNPlaneGeometry(device: MTLCreateSystemDefaultDevice()!)
        scenePlaneGeometry?.update(from: planeAnchor.geometry)
        let planeNode = SCNNode(geometry: scenePlaneGeometry)
        planeNode.name = "\(id)"
        switch planeAnchor.alignment {
        case .horizontal:
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
        case .vertical:
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.5)
            
        }
        return planeNode
    }
    
}

extension ArMesh: ARSCNViewDelegate, ARSessionObserver{
    
    func setupArSession(){
        //recieve AR anchor events
        sceneView.delegate = self
        
        //create configuration
        configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true;
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        }
        
        //setup lighting in scene
        sceneView.autoenablesDefaultLighting = true;
        sceneView.automaticallyUpdatesLighting = true;
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        let results = sceneView.hitTest(sceneView.center, types: [ .existingPlaneUsingGeometry, .estimatedHorizontalPlane, .featurePoint])
        guard let hitFeature = results.last else {
            print("nil")
            return
            
        }
        
        print(hitFeature.type)
        
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,
                                         hitTransform.m42,
                                         hitTransform.m43)
        
        self.node?.position = hitPosition
        
    }
    
    
    //session updates
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print(camera.trackingState)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("wasInterrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("interruptionEnded")
    }
    
    
    //node updates
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        print("anchor")
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        if #available(iOS 11.3, *) {
            print("plane: \(self.planeId)")
            let planeNode = SCNNode.createPlaneNode(planeAnchor: planeAnchor, id: self.planeId)
            self.planeId += 1
            node.addChildNode(planeNode)
        } else {
            // Fallback on earlier versions
        }

    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        node.enumerateChildNodes { child, _ in
            child.removeFromParentNode()
        }
        if #available(iOS 11.3, *) {
            let planeNode = SCNNode.createPlaneNode(planeAnchor: planeAnchor, id: planeId)
            self.planeId += 1
            node.addChildNode(planeNode)
        } else {
            // Fallback on earlier versions
        }

    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        node.enumerateChildNodes { child, _ in
            child.removeFromParentNode()
        }
    }
}



