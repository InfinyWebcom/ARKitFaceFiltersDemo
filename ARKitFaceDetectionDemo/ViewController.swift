//
//  ViewController.swift
//  ARKitFaceDetectionDemo
//
//  Created by Siddhesh on 18/11/21.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - @IBOutlet
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    
    // MARK: - Class Properties
    let noseOptions = ["👃", "🐽", "💧", " "]
    let eyeOptions = ["👁", "🌟", "🔥", "🔎", " "]
    let mouthOptions = ["👄", "👅", " "]
    let hatOptions = ["👒", "🎓", "🎩", "🧢", "⛑", " "]
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    
    var analysis = ""
    
    
    // to laod models
    var faceAnchorsAndContentControllers: [ARFaceAnchor: VirtualContentController] = [:]
    
    var selectedVirtualContent: VirtualContentType! {
        didSet {
            guard oldValue != nil, oldValue != selectedVirtualContent
                else { return }
            
            for contentController in faceAnchorsAndContentControllers.values {
                contentController.contentNode?.removeFromParentNode()
            }
            
            for anchor in faceAnchorsAndContentControllers.keys {
                let contentController = selectedVirtualContent.makeController()
                if let node = sceneView.node(for: anchor),
                let contentNode = contentController.renderer(sceneView, nodeFor: anchor) {
                    node.addChildNode(contentNode)
                    faceAnchorsAndContentControllers[anchor] = contentController
                }
            }
        }
    }
    
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true
        addGestureToSceneView()
        
        selectedVirtualContent = VirtualContentType(rawValue: 0)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetTracking()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Setup
    
    private func resetTracking(){
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        self.sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
        
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func scanForFaces() {
        
        //get the captured image of the ARSession's current frame
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        let image = CIImage.init(cvPixelBuffer: capturedImage)
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            print("detectFaceRequest results",request.results)
        }
        let imageOrientation: CGImagePropertyOrientation = .up
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: imageOrientation).perform([detectFaceRequest])
        }
    }
    
    // MARK: - expression checker
    func expression(anchor: ARFaceAnchor) {
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
        let smileRight = anchor.blendShapes[.mouthSmileRight]
        let cheekPuff = anchor.blendShapes[.cheekPuff]
        let tongue = anchor.blendShapes[.tongueOut]
        self.analysis = ""
        
        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 0.9 {
            self.analysis = "You are smiling. "
        }
        if cheekPuff?.decimalValue ?? 0.0 > 0.1 {
            self.analysis = "Your cheeks are puffed. "
        }
        if tongue?.decimalValue ?? 0.0 > 0.1 {
            self.analysis = "Don't stick your tongue out! "
        }
    }
    
    // MARK: - Face Overlays
    
    func filters() -> SCNNode{
        let noseNode = EmojiNode(with: noseOptions)
        noseNode.name = "nose"
        
        let leftEyeNode = EmojiNode(with: eyeOptions)
        leftEyeNode.name = "leftEye"
        leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
        
        let rightEyeNode = EmojiNode(with: eyeOptions)
        rightEyeNode.name = "rightEye"
        
        let mouthNode = EmojiNode(with: mouthOptions)
        mouthNode.name = "mouth"
        
        let hatNode = EmojiNode(with: hatOptions)
        hatNode.name = "hat"
        
        return noseNode
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        for (feature, indices) in zip(features, featureIndices) {
            let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
            
            switch feature {
            case "leftEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            case "rightEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            case "mouth":
                let jawOpenValue = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.2
                child?.scale = SCNVector3(1.0, 0.8 + jawOpenValue, 1.0)
            default:
                break
            }
        }
    }
    
    // MARK: - Gestures
    func addGestureToSceneView() {
        // to add or remove object on touch
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // chnage overlays on tap
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
//        let location = recognizer.location(in: sceneView)
//        let results = sceneView.hitTest(location, options: nil)
//        if let result = results.first,
//           let node = result.node as? EmojiNode {
//            node.next()
//        }
        if selectedVirtualContent == VirtualContentType(rawValue: 0){
            selectedVirtualContent = VirtualContentType(rawValue: 1)
        }else{
            selectedVirtualContent = VirtualContentType(rawValue: 0)
        }
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let device = sceneView.device else {
                  return nil
              }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        
        let node = SCNNode(geometry: faceGeometry)
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 0.0
        
        /*
         // to add face overlays
         let feature = filters()
         node.addChildNode(feature)
         updateFeatures(for: node, using: faceAnchor)
         */
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        DispatchQueue.main.async {
            let contentController = self.selectedVirtualContent.makeController()
            if node.childNodes.isEmpty, let contentNode = contentController.renderer(renderer, nodeFor: faceAnchor) {
                node.addChildNode(contentNode)
                self.faceAnchorsAndContentControllers[faceAnchor] = contentController
            }
        }
    }

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        guard let faceAnchor = anchor as? ARFaceAnchor,
            let contentController = faceAnchorsAndContentControllers[faceAnchor],
            let contentNode = contentController.contentNode,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
            return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
        /*
         // to detect expressions
         expression(anchor: faceAnchor)
         DispatchQueue.main.async {
         self.messageLabel.text = self.analysis
         }
         */
        
        /*
         // to update face overlay
         updateFeatures(for: node, using: faceAnchor)
         */
        
        contentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
}



