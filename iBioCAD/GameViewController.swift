//
//  GameViewController.swift
//  iBioCAD
//
//  Created by Rudy Aramayo on 1/5/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import SceneKit
import QuartzCore
import ARAPubChemToolsOSX
import ARA_RCSBToolsOSX

class GameViewController: NSViewController, ARAPubChemMoleculeSearchDelegate {
    
    
    var rna: SCNNode?
    var average_vec:SCNVector3 = SCNVector3Zero
    
    var pubChem:ARAPubChemToolbox!
    var molecule:SCNNode?
    var moleculeJSONNSDictionary:NSDictionary?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "art.scnassets/µEppendorf.scn")!
        scene.physicsWorld.speed = 0.1;
        
        pubChem = ARAPubChemToolbox()
        pubChem.initToolbox(search_delegate: self)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        //EXample to load from another scenekit storage file... store and save molecules like this?
        //can we add augmented data to the save file?
        /*
        let benzeneScene = SCNScene(named: "Benzene.scn")!
        let benzene = benzeneScene.rootNode.childNode(withName: "Benzene", recursively: true)!
        benzene.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(benzene)
        */
        
        
        
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = NSColor.black
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = scnView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        scnView.gestureRecognizers = gestureRecognizers
    }
    
    
    func didReturnPubChemMolecule(moleculeNode:NSDictionary)
    {
        print("didReturnPubChemMolecule")
        print(moleculeNode)

        moleculeJSONNSDictionary = moleculeNode
        let sceneView = self.view as! SCNView
        
        let sceneCamPos = SCNVector3Make((sceneView.pointOfView?.position.x)!, (sceneView.pointOfView?.position.y)!, (sceneView.pointOfView?.position.z)!)
        DispatchQueue.main.async {
            self.pubChem.loadPubChemMolecule(jsonResponse: self.moleculeJSONNSDictionary!,
                                             targetScene: sceneView.scene!,
                                             targetNode:(sceneView.scene?.rootNode)!,
                                             targetPosition:sceneCamPos)
        }
    }
    
    
    func didFailToReturnPubChemMolecule(message:String, details:String)
    {
        print(message)
        print(details)
        
        let alert: NSAlert = NSAlert()
        alert.messageText = message
        alert.informativeText = details
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let res = alert.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            return
        }
    }
    
    
    
    @objc
    @IBAction func saveBioScriptAction(sender:AnyObject)
    {
        let scnView = self.view as! SCNView
        
        DispatchQueue.main.async {
            
            guard let window = self.view.window else { return }
            
            let panel = NSSavePanel()
            panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            panel.nameFieldStringValue = "exportSceneKitFile.scn"
            
            panel.beginSheetModal(for: window) { (result) in
                if result == NSApplication.ModalResponse.OK,
                    let url = panel.url {
                    let success = scnView.scene?.write(to: url, options: nil, delegate: nil , progressHandler: {(totalProgress, error, stop) -> Void in
                        print(totalProgress)
                    })
                }
            }
        }
    }
    
    
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        
        
        let scnView = self.view as! SCNView
        
        //self.pubChem_compoundSearchByName(searchTerm:"benzene", record_type: "3d") //Make sure to look up a broken gvalue here for robustness and replace ! with ?
        //self.pubChem_compoudSearchByCID(searchTerm:"86583373", record_type: "") //some 2d RNA with no conformer
        //self.pubChem_compoudSearchByCID(searchTerm:"16197306", record_type: "") //some 2d DNA with no conformer
        //self.pubChem_compoudSearchByCID(searchTerm:"11979623", record_type: "") //some 2d Double strand of RNA with no conformer
        
        //self.pubChem.pubChem_compoudSearchByCID(searchTerm: "11979623", record_type_3d:false)
        self.pubChem.pubChem_compoudSearchByCID(searchTerm: "86583373", record_type_3d:false)
        
        // check what nodes are clicked
        let p = gestureRecognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
    }
    
}
