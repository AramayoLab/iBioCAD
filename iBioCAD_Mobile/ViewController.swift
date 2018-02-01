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
import ReplayKit


class ViewController: UIViewController, ARSCNViewDelegate, ARAPubChemMoleculeSearchDelegate, UITextFieldDelegate, RPPreviewViewControllerDelegate {
    

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var searchTextField: UITextField!
    
    @IBOutlet var stopRecButton:UIButton!
    @IBOutlet var startRecButton:UIButton!
    
    var pubChem:ARAPubChemToolbox!
    var molecule:SCNNode?
    var moleculeJSONNSDictionary:NSDictionary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopRecButton.isHidden = true;
        startRecButton.isHidden = false;
        
        // Set the view's delegate
        sceneView.delegate = self
        searchTextField.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/µEppendorf.scn")!

        pubChem = ARAPubChemToolbox()
        pubChem.initToolbox(search_delegate: self)
        
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Set the scene to the view
        sceneView.scene = scene
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
    
    
    @IBAction func startRecording(sender:Any)
    {
        RPScreenRecorder.shared().startRecording(handler: { error in
            DispatchQueue.main.async {
                self.stopRecButton.isHidden = false;
                self.startRecButton.isHidden = true;
            }
        })

    }
    

    @IBAction func stopRecording(sender:Any)
    {
        RPScreenRecorder.shared().stopRecording(handler: { (rpVC, error) in
            self.present(rpVC!, animated: true, completion: { rpVC!.previewControllerDelegate = self })
        })
        
    }
    
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController)
    {
        
        DispatchQueue.main.async {
            self.stopRecButton.isHidden = true
            self.startRecButton.isHidden = false
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchAction(sender: self)
        return true
    }
    
    func didReturnPubChemMolecule(moleculeNode:NSDictionary)
    {
        print("didReturnPubChemMolecule")
        print(moleculeNode)
        moleculeJSONNSDictionary = moleculeNode
    }
    
    
    func didFailToReturnPubChemMolecule(message:String, details:String)
    {
        print(message)
        print(details)
        
        let alert = UIAlertController(title: message, message: details, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
                
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
                
                
            }}))
    }

    
    @IBAction func searchAction(sender:Any)
    {
        self.searchTextField.resignFirstResponder()
        
        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        let searchByName_ActionButton = UIAlertAction(title: "Name", style: .default) { action -> Void in
            self.pubChem.pubChem_compoundSearchByName(searchTerm: self.searchTextField.text!, record_type_3d: true)
            
        }
        actionSheetController.addAction(searchByName_ActionButton)
        
        let searchByCID_ActionButton = UIAlertAction(title: "CID", style: .default) { action -> Void in
            self.pubChem.pubChem_compoudSearchByCID(searchTerm: self.searchTextField.text!, record_type_3d: false)
            
        }
        actionSheetController.addAction(searchByCID_ActionButton)
        self.present(actionSheetController, animated: true, completion: nil)
        
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
        
        let sceneCamPos = SCNVector3Make((sceneView.pointOfView?.position.x)!, (sceneView.pointOfView?.position.y)!, (sceneView.pointOfView?.position.z)!)

        self.pubChem.loadPubChemMolecule(jsonResponse: moleculeJSONNSDictionary!,
                                         targetScene: sceneView.scene,
                                         targetNode:node,
                                         position:sceneCamPos)
    
    }
    
    
}
