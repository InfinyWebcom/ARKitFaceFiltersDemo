//
//  Head.swift
//  ARKitFaceDetectionDemo
//
//  Created by Siddhesh on 03/12/21.
//

import UIKit
import ARKit

class PlagueMask: SCNNode, VirtualContentController {
    
    var contentNode: SCNReferenceNode?
    
    override init(){
        super.init()
        guard let scnFileURL = Bundle.main.url(forResource: "plagueMask", withExtension: "usdz", subdirectory: "Models.scnassets") else {
            print("fail to get scnFile")
            
            return
        }
        
        contentNode = SCNReferenceNode(url: scnFileURL)
        
        guard let contentNode = contentNode else {
            return
        }
        contentNode.load()
        contentNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        contentNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
}
