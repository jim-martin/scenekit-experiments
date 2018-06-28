//
//  DepthViewController.swift
//  learning-scenekit
//
//  Created by Jim Martin on 6/20/18.
//  Copyright © 2018 Jim Martin. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

class DepthViewController: UIViewController {
    
    @IBOutlet weak var sceneView: DepthSceneView!
    private var scene: SCNScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = SCNScene()
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
        lightNode.light?.castsShadow = true;
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
        
        let cube : SCNBox = SCNBox(width: 3, height: 0.2, length: 3, chamferRadius: 0.0)
        let cubeMaterial = SCNMaterial()
        //        cubeMaterial.diffuse.contents = UIImage(named: "art.scnassets/UV_Grid_Sm.png")
        cube.firstMaterial = cubeMaterial
        
        //        let waveShader = ShaderData( filename: "cloud", entryPoint: SCNShaderModifierEntryPoint.fragment)
        //        cubeMaterial.applyShaderModifier(shader: waveShader)
        
        ///??? ___ shader experimenting ___ ???
        
        let program = SCNProgram()
        program.fragmentFunctionName = "cloudFragment"
        program.vertexFunctionName = "cloudVertex"
        program.isOpaque = false;
        cubeMaterial.program = program
        
        //set debug texture
        let image = UIImage(named: "art.scnassets/UV_Grid_Sm.png")!
        let imageProperty = SCNMaterialProperty(contents: image)
        cubeMaterial.setValue(imageProperty, forKey: "debugTexture")
        
        //set noise texture
        let noiseImage  = UIImage(named: "art.scnassets/PerlinFullSoft.png")!
        let noiseImageProperty = SCNMaterialProperty(contents: noiseImage)
        cubeMaterial.setValue(noiseImageProperty, forKey: "noiseTexture")
        
        let geometryNode: SCNNode = SCNNode(geometry: cube)
        scene.rootNode.addChildNode(geometryNode)
        geometryNode.worldPosition = SCNVector3(0,1, 0);
        
        let occlusionNode: SCNNode = SCNNode(geometry: SCNBox(width: 3, height: 0.4, length: 3, chamferRadius: 0));
        scene.rootNode.addChildNode(occlusionNode);
        occlusionNode.position.y += 0.3;
        
        let shadowNode: SCNNode = SCNNode(geometry: SCNBox(width: 1, height: 0.2, length: 1, chamferRadius: 0));
        scene.rootNode.addChildNode(shadowNode);
        shadowNode.castsShadow = true;
        shadowNode.position.y += 1.5;
    }
    
}

class DepthSceneView: SCNView {
    
    var scnRenderer : SCNRenderer!
    var depthTex : MTLTexture!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scnRenderer = SCNRenderer(device: device!, options: nil)
        updateDepthTex()
    }
    
    func updateDepthTex()
    {
        let depthDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float, width: Int(frame.width), height: Int(frame.height), mipmapped: false)
        depthDescriptor.resourceOptions = .storageModePrivate
        depthDescriptor.usage = .renderTarget
        depthTex = device!.makeTexture(descriptor: depthDescriptor)
        depthTex.label = "Depth Texture"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        renderDepthFrame()

        var p = self.convert((touches.first?.location(in: self))!, from: nil)

        print("window point: \(p)")

        p.x = floor(p.x)+0.5
        p.y = floor(p.y)+0.5

        // Look into the depth texture at the point.
        let depthImageBuffer: MTLBuffer = device!.makeBuffer(length: MemoryLayout<Float>.size, options: .storageModeShared)!
        depthImageBuffer.label   = "Depth"

        let commandBuffer = commandQueue!.makeCommandBuffer()

        let blitCommandEncoder: MTLBlitCommandEncoder = commandBuffer!.makeBlitCommandEncoder()!
        blitCommandEncoder.copy(from: depthTex, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(p.x), Int(frame.height-p.y), 0), sourceSize: MTLSizeMake(1, 1, 1), to: depthImageBuffer, destinationOffset: 0, destinationBytesPerRow: 4, destinationBytesPerImage: 4)
        blitCommandEncoder.endEncoding()

        commandBuffer?.addCompletedHandler({(buffer) -> Void in
            let rawPointer: UnsafeMutableRawPointer = UnsafeMutableRawPointer(mutating: depthImageBuffer.contents())
            let typedPointer: UnsafeMutablePointer<Float> = rawPointer.assumingMemoryBound(to: Float.self)
            let z = typedPointer.pointee

            print("results ------------")

            print("depth value at mouse: \(z)")

            // Unproject the point.
            let pScene = self.unprojectPoint(SCNVector3(x: Float(p.x), y: Float(p.y), z: z))

            print("unprojected point: \(pScene)")

            let hitResults = self.hitTest(p, options: [:])
            // check that we clicked on at least one object
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result = hitResults[0]

                print("hit test worldCoordinates: \(result.worldCoordinates)")
            }

        })

        commandBuffer?.commit()

        super.touchesBegan(touches, with: event)
    }

    func renderDepthFrame() {

        if depthTex.width != Int(frame.width) || depthTex.height != Int(frame.height)
        {
            updateDepthTex()
        }

        // depth pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.depthAttachment.texture = depthTex
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderPassDescriptor.depthAttachment.storeAction = .store

        let commandBuffer = commandQueue!.makeCommandBuffer()

        scnRenderer.scene = scene
        scnRenderer.pointOfView = pointOfView!

        scnRenderer.render(atTime: 0, viewport: frame, commandBuffer: commandBuffer!, passDescriptor: renderPassDescriptor)

        commandBuffer?.commit()

    }
}
