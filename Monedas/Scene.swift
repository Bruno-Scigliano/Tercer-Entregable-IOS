//
//  Scene.swift
//  Monedas
//
//  Created by Bruno Scigliano on 6/25/18.
//  Copyright © 2018 123. All rights reserved.
//

import SpriteKit
import ARKit
import Vision

class Scene: SKScene {
    
    var sumLabel: UILabel!

    var anchors: [ARAnchor]    = []
    var oldAnchors: [ARAnchor] = []
    let dispatchQueueML        = DispatchQueue(label: "dispatchqueueml")
    var canLoopScene: Bool     = false
    let labels: [String]       = getModelLabels()
    
    override func didMove(to view: SKView) {
        // Setup your scene here
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func loopScene(){
        if(self.canLoopScene){
                self.dispatchQueueML.async {
                    sleep(1)
                    self.updateScene()
                    self.loopScene()
                }
        }
    }
    func updateScene() {
        guard let sceneView = self.view as? ARSKView else {
            return
        }
        if let currentFrame = sceneView.session.currentFrame {
            do {
                let vNModel = try VNCoreMLModel(for: CoinRecognizer().model)
                let request = VNCoreMLRequest(model: vNModel, completionHandler: { (request, error) in
                    guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
                        self.setSumLabel(sum: "Nothing detected")
                        return
                    }
                    let predictions = getPredictions(confidence: results[1].featureValue.multiArrayValue!, coordinates: results[0].featureValue.multiArrayValue!)
                    if predictions.count == 0 {
                        self.setSumLabel(sum: "Nothing detected")
                        return
                    }
                    var sum = 0
                    var label = ""
                    for p in predictions {
                        label = self.labels[p.labelIndex]
                        sum += getCoinValue(coinClass: label)
                        self.setAnchor(label: label, boundingBox: p.boundingBox, currentFrame: currentFrame, sceneView: sceneView)
                    }
                    self.setSumLabel(sum: String(sum))
                    self.removeOldAnchors(sceneView: sceneView)
                })
                let handler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage, options: [:])
                try handler.perform([request])
            } catch {
                //Handle the catch
            }
        }
    }
    
    func setAnchor(label: String, boundingBox: CGRect, currentFrame: ARFrame, sceneView: ARSKView) {
        let rectCenter = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let hitTestResults = currentFrame.hitTest(rectCenter, types: [.existingPlaneUsingExtent, .featurePoint])
        if let closestResult = hitTestResults.first {
            let position : matrix_float4x4 = closestResult.worldTransform
            let anchor = ARAnchor(transform: position)
            ARBridge.shared.anchorsToIdentifiers[anchor] = String(getCoinValue(coinClass: label))
            sceneView.session.add(anchor: anchor)
            self.anchors.append(anchor)
        }
    }
    
    func removeOldAnchors(sceneView: ARSKView) {
        for anchor in self.oldAnchors{
            sceneView.session.remove(anchor: anchor)
        }
        self.oldAnchors.removeAll()
        self.oldAnchors = self.anchors
        self.anchors = []
    }
    
    func setSumLabel (sum: String) {
        DispatchQueue.main.async {
            self.sumLabel?.text = sum
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        canLoopScene = !canLoopScene
        if (canLoopScene) {
            sumLabel.text = "Processing..."
            loopScene()
        }
    }
}
