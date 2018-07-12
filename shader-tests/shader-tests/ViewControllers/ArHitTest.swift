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

class ArHitTest: UIViewController {
    
    //scene and AR setup
    @IBOutlet var sceneView: ARSCNView!
    var scene: SCNScene!
    var configuration: ARWorldTrackingConfiguration!
    var planeId: Int = 0
    
    //hittest node
    var smoothedNode: SCNNode!
    
    //smoothed hittest nodes
    var smoothedTestNodes: [SCNNode]!
    
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
        smoothedNode = SCNNode(geometry: SCNSphere(radius: 0.02))
        smoothedNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        scene.rootNode.addChildNode(smoothedNode)
        
        //setup smoothed hittestnodes
        smoothedTestNodes = [SCNNode]()
        for i in 0..<5 {
            smoothedTestNodes.append(SCNNode(geometry: SCNSphere(radius: 0.01)))
            scene.rootNode.addChildNode(smoothedTestNodes[i])
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let position = event?.touches(for: sceneView)?.first?.location(in: sceneView)
        let smoothedHitPosition = sceneView.smoothedHitTest(position!, types: [ .existingPlaneUsingGeometry, .estimatedHorizontalPlane, .featurePoint], smoothingRadius: 30, testNodes: smoothedTestNodes)
        
        smoothedNode.position = smoothedHitPosition

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

extension ARSCNView {
    
    @objc func smoothedHitTest(_ point: CGPoint, types: ARHitTestResult.ResultType, smoothingRadius: CGFloat, testNodes: [SCNNode]?) -> SCNVector3 {
        
        //use smoothing radius to define a set of hittest samples
        let samplePoints = [
            point, //center
            CGPoint(x: point.x, y: point.y + smoothingRadius), //up
            CGPoint(x: point.x, y: point.y - smoothingRadius), //down
            CGPoint(x: point.x - smoothingRadius, y: point.y), //left
            CGPoint(x: point.x + smoothingRadius, y: point.y)  //right
        ]
        
        //collect sample results in world-space
        var sampleResults = [SCNVector3]()
        var smoothedResult = SCNVector3Make(0, 0, 0)
        
        for i in 0..<samplePoints.count {

            //do a hittest for each point
            let results = self.hitTest(samplePoints[i], types:types)
            guard let hitFeature = results.last else {
                //fade the test node and move the next sample
                testNodes?[i].opacity = 0.2
                continue
            }
            
            //add the sample result if the hittest returned a feature
            let hitTransform = SCNMatrix4(hitFeature.worldTransform)
            let hitPosition = SCNVector3Make(hitTransform.m41,
                                             hitTransform.m42,
                                             hitTransform.m43)
            sampleResults.append(hitPosition)
            
            //move the test nodes if they exist
            testNodes?[i].position = hitPosition
            testNodes?[i].opacity = 0.8
        }
        
        //average samples
        for sample in sampleResults {
            smoothedResult = smoothedResult + sample
        }
        smoothedResult = smoothedResult / Float(sampleResults.count)
        
        return smoothedResult
    }
    
}

extension ArHitTest: ARSCNViewDelegate, ARSessionObserver{
    
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
        
//        let results = sceneView.hitTest(sceneView.center, types: [ .existingPlaneUsingGeometry, .estimatedHorizontalPlane, .featurePoint])
//        guard let hitFeature = results.last else {
//            print("nil")
//            return
//
//        }
//
//        print(hitFeature.type)
//
//        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
//        let hitPosition = SCNVector3Make(hitTransform.m41,
//                                         hitTransform.m42,
//                                         hitTransform.m43)
//
//        self.node?.position = hitPosition
        
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



