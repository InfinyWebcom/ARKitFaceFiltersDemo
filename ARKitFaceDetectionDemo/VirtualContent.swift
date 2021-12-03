//
//  VirtualContent.swift
//  ARKitFaceDetectionDemo
//
//  Created by Siddhesh on 03/12/21.
//

import UIKit
import ARKit


protocol VirtualContentController: ARSCNViewDelegate {
    /// The root node for the virtual content.
    var contentNode: SCNReferenceNode? { get set }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}


enum VirtualContentType: Int {
    case head, robotHead
    
    func makeController() -> VirtualContentController {
        switch self {
            
        case .head:
            return PlagueMask()
        case .robotHead:
            return RobotHead()
        }
    }
}
