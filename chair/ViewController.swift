//
//  ViewController.swift
//  chair
//
//  Created by popCorn on 2018/07/15.
//  Copyright © 2018 popCorn. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    private var hud: MBProgressHUD!
    private var newAngleY: Float = 0.0
    private var currentAngleY: Float = 0.0
    private var localTranslatePosition: CGPoint!
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.autoenablesDefaultLighting = true
        
        self.hud = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
        self.hud.label.text = "detecting plane..."
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    // function touch screen to add object in
    private func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //how to scale object
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        //how to rotating the object
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        
        //moving the object
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    //moving
    @objc func longPressed(recognizer: UILongPressGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else {
            return
        }
        
        let touch = recognizer.location(in: sceneView)
        let hitTestResults = self.sceneView.hitTest(touch, options: nil)
        
        if  let hitTest = hitTestResults.first {
            if let parentNode = hitTest.node.parent {
                if recognizer.state == .began {
                    localTranslatePosition = touch
                } else if recognizer.state == .changed {
                    //moving
                    let deltaX = (touch.x - self.localTranslatePosition.x)/700
                    let deltaY = (touch.y - self.localTranslatePosition.y)/700
                    
                    parentNode.localTranslate(by: SCNVector3(deltaX, 0.0, deltaY))
                    self.localTranslatePosition = touch
                }
            }
        }
        
    }
    
    //rotate using translation
    @objc func panned(recognizer: UIPanGestureRecognizer) {
        if  recognizer.state == .changed {
            guard let sceneView = recognizer.view as? ARSCNView else {
                return
            }
            let touch = recognizer.location(in: sceneView)
            let translation = recognizer.translation(in: sceneView)
            
            let hitTestResults = self.sceneView.hitTest(touch, options: nil)
            
            if let hitTest = hitTestResults.first {
                let parentNode = hitTest.node
                self.newAngleY = Float(translation.x) * (Float)(Double.pi)/180
                self.newAngleY += self.currentAngleY
                parentNode.eulerAngles.y = self.newAngleY
                
            }
        }
        //
        else if recognizer.state == .ended {
            self.currentAngleY = self.newAngleY
        }
    }
    
    @objc func pinched(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .changed {
            guard let sceneView = recognizer.view as? ARSCNView else {
                return
            }
            
            let touch = recognizer.location(in: sceneView)
            
            let hitTestResults = self.sceneView.hitTest(touch, options: nil)
            if let hitTest = hitTestResults.first {
                let chairNode = hitTest.node
                let pinchScaleX = Float(recognizer.scale) * chairNode.scale.x
                let pinchScaleY = Float(recognizer.scale) * chairNode.scale.y
                let pinchScaleZ = Float(recognizer.scale) * chairNode.scale.z
                // how many time the chair was scale
                
                chairNode.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
                recognizer.scale = 1
            }
            
        }
    }
    
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else {
            return
        }
        
        let touch = recognizer.location(in: sceneView)
        
        let hitTestResults = sceneView.hitTest(touch, types: .existingPlane) //
        
        if  let hitTest = hitTestResults.first {
            let chairScene  = SCNScene(named: "art.scnassets/chair.dae")!
            guard let chairNode = chairScene.rootNode.childNode(withName: "chair", recursively: true) else {
                return
            }
            chairNode.position = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z)
            
            // add child node into rootNode
            self.sceneView.scene.rootNode.addChildNode(chairNode)
            
        }
    }
    
    ////
    //
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            //the plane is detected
            DispatchQueue.main.sync {
                self.hud.label.text = "Plane detected"
                self.hud.hide(animated: true, afterDelay: 1.0)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //looking for flat plane to put our object
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

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
