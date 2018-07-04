//
//  ViewController.swift
//  Monedas
//
//  Created by Bruno Scigliano on 6/25/18.
//  Copyright © 2018 123. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit

class ARViewController: UIViewController, ARSKViewDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    @IBOutlet weak var sumLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
    
        // Load the SKScene from 'Scene.sks'
        let scene = Scene(size: self.view.frame.size)
        scene.sumLabel = sumLabel
        sceneView.presentScene(scene)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSKViewDelegate


    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {

        guard let identifier = ARBridge.shared.anchorsToIdentifiers[anchor] else {
            return nil
        }
        
        let labelNode = SKLabelNode(text: identifier)
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.fontName = UIFont.boldSystemFont(ofSize: 100).fontName
        labelNode.fontSize = 8
        labelNode.fontColor = .black
        return labelNode
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    @IBAction func goToPictureRecognizer(_ sender: Any) {
        performSegue(withIdentifier: "goToPicture", sender: nil)
    }
}
