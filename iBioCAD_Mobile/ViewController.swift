//
//  ViewController.swift
//  iBioCAD_Mobile
//
//  Created by Rudy Aramayo on 1/27/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ARAPubChemTools


class ViewController: UIViewController, ARSCNViewDelegate, ARAPubChemMoleculeSearchDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var molecule:SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //let scene = SCNScene(named: "BenzeneReaction1.scn")!

        //ARAPubChemToolbox Test Function
        //ARAPubChemToolbox.printme_imdelicate()
        
        let t = ARAPubChemToolbox()
        t.initToolbox(search_delegate: self, new_scene: scene)
        //t.pubChem_compoundSearchByName(searchTerm: "benzene", record_type_3d: true)
        t.pubChem_compoudSearchByCID(searchTerm: "86583373", record_type_3d:false)
        
        
        //let v = ARAPubChemSearch.pubChem_compoudSearchByCID()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        if let touchLocation = touches.first?.location(in: sceneView) {
            
            // Touch to 3D Object
            if let hit = sceneView.hitTest(touchLocation, options: nil).first {
                hit.node.removeFromParentNode()
                return
            }
            
            // Touch to Feature Point
            if let hit = sceneView.hitTest(touchLocation, types: .featurePoint).first {
                sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if ( molecule != nil)
        {
            //let moleculeClone = molecule!.clone()
            molecule?.removeFromParentNode()
            molecule!.position = SCNVector3Make(0, 0, 0)
            node.addChildNode(molecule!)
            
            //let ship = sceneView.scene.rootNode.childNode(withName: "ship", recursively: true)
            //ship!.addChildNode(moleculeClone)
            
        }
    }
    
    
    func didReturnPubChemMolecule(moleculeNode:SCNNode)
    {
        print("didReturnPubChemMolecule")
        print(moleculeNode)
        molecule = moleculeNode
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

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
