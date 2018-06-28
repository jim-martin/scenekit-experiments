//
//  SCNUIView.swift
//  WeatherOverground
//
//  Created by Jim Martin on 6/25/18.
//  Copyright © 2018 Avi Cieplinski. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class SCNUIView: UIView, SCNSceneRendererDelegate {
    
    private var trackedNode = SCNNode()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //including the scene lets us use a general delegate, and still render the node's geometry
    public func TrackNodeInScene( node: SCNNode, inView: SCNView){
        
        inView.delegate = self
        trackedNode = node;
    }
    
    @objc public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
    
        let screenPoint = renderer.projectPoint(trackedNode.worldPosition)
        
        UI {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut, animations: {
                self.transform = CGAffineTransform(translationX: CGFloat(screenPoint.x), y: CGFloat(screenPoint.y))
            })
            animator.startAnimation()
        }
    }
}
