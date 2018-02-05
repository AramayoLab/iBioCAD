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
import ReplayKit

import ARAPubChemTools
import ARA_RCSBTools


class ViewController: UIViewController, ARSCNViewDelegate, ARAPubChemMoleculeSearchDelegate, ARA_RCSB_PDBSearchDelegate, UITextFieldDelegate, RPPreviewViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var searchField:UISearchBar!
    @IBOutlet var searchController: UISearchController!
    @IBOutlet var stopRecButton:UIButton!
    @IBOutlet var startRecButton:UIButton!
    
    var pubChem:ARAPubChemToolbox!
    var rcsb:ARA_RCSBToolbox!
    
    var search_type:String!
    var recent_searches:[[String:String]] = [[:]]
    
    let kChemical_NameSearchType = "kChemical_NameSearchType"
    let kChemical_CIDSearchType = "kChemical_CIDSearchType"
    
    let kChemical_2DAtoms = "kChemical_2DAtoms"
    let kChemical_3DAtoms = "kChemical_3DAtoms"
    
    let kPDB_SearchType = "kPDB_SearchType"
    
    let kSearchTypeKey = "kSearchTypeKey"
    let kSearchTermKey = "kSearchTermKey"
    let kSearchOptionKey = "kSearchOptionKey"
    
    
    var molecule:SCNNode?
    var moleculeJSONNSDictionary:NSDictionary?
    
    var rcsb_pdbFileArray:[String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if (UserDefaults.standard.value(forKey: "RecentSearches") == nil)
        {
            recent_searches = [[kSearchTermKey:"water", kSearchTypeKey:kChemical_NameSearchType, kSearchOptionKey:kChemical_3DAtoms],
                               [kSearchTermKey:"benzene", kSearchTypeKey:kChemical_NameSearchType, kSearchOptionKey:kChemical_3DAtoms],
                               [kSearchTermKey:"86583373", kSearchTypeKey:kChemical_CIDSearchType, kSearchOptionKey:kChemical_2DAtoms],
                               [kSearchTermKey:"246D", kSearchTypeKey:kPDB_SearchType]]
            
            UserDefaults.standard.set(recent_searches, forKey: "RecentSearches")
        }
        

        
        stopRecButton.isHidden = true;
        startRecButton.isHidden = false;
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/µEppendorf.scn")!
        
        pubChem = ARAPubChemToolbox()
        pubChem.initToolbox(search_delegate: self)
        
        rcsb = ARA_RCSBToolbox()
        rcsb.initToolbox(search_delegate: self)
        
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
        print("ARSession, didFailWithError")
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        print("ARSession, sessionWasInterrupted")
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("ARSession, sessionInterruptionEnded")
    }
    
    
    func didReturnPubChemMolecule(moleculeNode:NSDictionary)
    {
        print("didReturnPubChemMolecule")
        print(moleculeNode)
        moleculeJSONNSDictionary = moleculeNode
    }
    
    
    func didFailToReturnPubChemMolecule(message:String, details:String)
    {
        self.didFailAlert(message:message , details:details)
    }

    
    func didFailAlert(message:String, details:String)
    {
        let alert = UIAlertController(title: message, message: details, preferredStyle: UIAlertControllerStyle.alert)
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
    
    
    func didReturnPDB(pdb:[String])
    {
        print("didReturnPDB")
        rcsb_pdbFileArray = pdb
    }
    
    
    func didFailToReturnPubPDB(message:String, details:String)
    {
        self.didFailAlert(message:message , details:details)
    }
    

    @IBAction func searchAction(sender:Any)
    {
        switch self.searchField.selectedScopeButtonIndex {
            case 0:
                //name
                self.search_type = self.kChemical_NameSearchType
                self.pubChem.pubChem_compoundSearchByName(searchTerm: self.searchField.text!, record_type_3d: true)
            case 1:
                //CID
                self.search_type = self.kChemical_CIDSearchType
                self.pubChem.pubChem_compoudSearchByCID(searchTerm: self.searchField.text!, record_type_3d: false)
            case 2:
                //PDB
                self.search_type = self.kPDB_SearchType
                self.rcsb.rcsb_pdbSearchByID(searchTerm: self.searchField.text!)
            
            default:
                print("error")
        }
        
        self.searchController.isActive = false
    }
    
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        
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

        if (rcsb_pdbFileArray != nil && search_type == kPDB_SearchType)
        {
            rcsb.loadPDBJsonMolecule(pdbArray:rcsb_pdbFileArray!,
                                     targetScene: sceneView.scene,
                                     targetNode: node,
                                     targetPosition: sceneCamPos)
        }
        
        if (moleculeJSONNSDictionary != nil && (search_type == kChemical_NameSearchType || search_type == kChemical_CIDSearchType))
        {
            self.pubChem.loadPubChemMolecule(jsonResponse: moleculeJSONNSDictionary!,
                                             targetScene: sceneView.scene,
                                             targetNode:node,
                                             targetPosition:sceneCamPos)
        }
    
    }
    

    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        self.recent_searches = UserDefaults.standard.value(forKey: "RecentSearches") as! [[String:String]]

        return recent_searches.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = self.recent_searches[indexPath.row][kSearchTermKey]
        cell.detailTextLabel?.text = self.recent_searches[indexPath.row][kSearchTypeKey]
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("click tableview")
        
        let cell = tableView.cellForRow(at: indexPath)
        self.searchField.text = cell?.textLabel?.text
        self.searchAction(sender: self)
        self.searchController.isActive = false

    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchAction(sender: self)
        self.searchController.isActive = false
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
}
