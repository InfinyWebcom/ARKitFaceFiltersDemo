//
//  RobotHead.swift
//  ARKitFaceDetectionDemo
//
//  Created by Siddhesh on 03/12/21.
//

import UIKit
import ARKit

class RobotHead: SCNNode, VirtualContentController{
    
    var contentNode: SCNReferenceNode?
    
    lazy var jawNode = contentNode!.childNode(withName: "jaw", recursively: true)!
    lazy var eyeLeftNode = contentNode!.childNode(withName: "eyeLeft", recursively: true)!
    lazy var eyeRightNode = contentNode!.childNode(withName: "eyeRight", recursively: true)!
    
    lazy var jawHeight: Float = {
        let (min, max) = jawNode.boundingBox
        return max.y - min.y
    }()
    
    var originalJawY: Float = 0
    
    override init(){
        super.init()
        guard let scnFileURL = Bundle.main.url(forResource: "robotHead", withExtension: "scn", subdirectory: "Models.scnassets") else {
            print("fail to get scnFile")
            return
        }
        
        contentNode = SCNReferenceNode(url: scnFileURL)
        
        guard let contentNode = contentNode else {
            return
        }
        contentNode.load()
        originalJawY = jawNode.position.y
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        contentNode
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor
        else { return }
        
        let blendShapes = faceAnchor.blendShapes
        guard let eyeBlinkLeft = blendShapes[.eyeBlinkLeft] as? Float,
              let eyeBlinkRight = blendShapes[.eyeBlinkRight] as? Float,
              let jawOpen = blendShapes[.jawOpen] as? Float
        else { return }
        eyeLeftNode.scale.z = 1 - eyeBlinkLeft
        eyeRightNode.scale.z = 1 - eyeBlinkRight
        jawNode.position.y = originalJawY - jawHeight * jawOpen
    }
}
