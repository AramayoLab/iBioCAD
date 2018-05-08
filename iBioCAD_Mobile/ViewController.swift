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


enum BenchTrackingState: Int {
    case position = 0
    case start
    case inAction
    case select
    case next
}

class ViewController: UIViewController, ARSCNViewDelegate, ARAPubChemMoleculeSearchDelegate, ARA_RCSB_PDBSearchDelegate, UITextFieldDelegate, RPPreviewViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var toast: UIVisualEffectView!
    @IBOutlet weak var label: UILabel!

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var searchField:UISearchBar!
    @IBOutlet var searchController: UISearchController!
    @IBOutlet var stopRecButton:UIButton!
    @IBOutlet var startRecButton:UIButton!
    
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var informationContainerView: UIView!
    
    
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
    
    var planeNodes:[SCNNode] = []
    var molecule:SCNNode?
    var moleculeJSONNSDictionary:NSDictionary?
    
    var rcsb_pdbFileArray:[String]?
    
    private var state: BenchTrackingState = .position {
        didSet {
            handleBenchState()
        }
    }
    
    private func handleBenchState() {
        switch state {
        case .inAction:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 0.0
            }
            self.showMessage("")
            
        case .select:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 1.0
            }
            self.showMessage("Choose a cup")
            
        case .start:
            
            for node in planeNodes
            {
                node.removeFromParentNode()
            }
            DispatchQueue.main.async {
                //self.resultsPanelView.isHidden = false
                //self.informationCenterYConstraint.constant = self.view.frame.height/3
                self.view.layoutIfNeeded()
            }
            self.showMessage("Tap to start", animated: true, duration: 0.3)
            //showToast("Tap to start")
        case .next:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 1.0
            }
            self.showMessage("Tap to continue")
        case .position: fallthrough
        default: break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toast.layer.masksToBounds = true
        toast.layer.cornerRadius = 7.5
        
        if (UserDefaults.standard.value(forKey: "RecentPDB") != nil)
        {
            print("Loaded recent pdb...")
            rcsb_pdbFileArray = UserDefaults.standard.value(forKey: "RecentPDB") as? [String]
            search_type = kPDB_SearchType
        }
        
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
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedInSceneView)))
        
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
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]

        showMessage("Move device to find a plane", animated: true, duration: 2)
    }
    
    private func showMessage(_ message: String, animated: Bool = false, duration: TimeInterval = 1.0) {
        DispatchQueue.main.async {
            if animated {
                UIView.animate(withDuration: duration, animations: {
                    self.informationLabel.alpha = 0.0
                    self.informationContainerView.alpha = 0.0
                }) { _ in
                    self.informationLabel.text = message
                    self.informationLabel.alpha = 0.0
                    self.informationContainerView.alpha = 0.0
                    UIView.animate(withDuration: duration, animations: {
                        self.informationLabel.alpha = 1.0
                        self.informationContainerView.alpha = 1.0
                    })
                }
            } else {
                self.informationLabel.text = message
            }
        }
    }
    
    private lazy var benchNode: SCNNode = {
        guard let node = sceneView.scene.rootNode.childNode(withName: "bench", recursively: true) else {
            preconditionFailure("Bench node not found")
        }
        node.position = SCNVector3 (0, -0.1, -0.5)
        return node
    }()
    
    
    @objc private func tappedInSceneView(recognizer: UIGestureRecognizer) {
        if state == .position {
            let touchLocation = recognizer.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlane)
            
            guard let hitResult = hitTestResult.first else {
                print("HitResult is empty")
                return
            }
            
            benchNode.transform = SCNMatrix4(hitResult.worldTransform)
            let camera = self.sceneView.pointOfView!
            benchNode.rotation = SCNVector4(0, 1, 0, camera.rotation.y)
            benchNode.isHidden = false
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
            
            state = .start
        } else if state == .start {
            state = .inAction
            
            //lift cup up, wait, then put down
            //run() does some animations then goes into .select mode
            self.state = .select
            
        } else if state == .select {
            /*let touchLocation = recognizer.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
            
            guard let hitResult = hitTestResult.first else {
                print("HitResult is empty")
                return
            }
            
            if let cup = hitResult.node.parent, let selectedCup = cupsNodes.index(of: cup) {
                let actualBallPosition = cupsPermutation[indexOfCupWithBall]
                let selectedBallPosition = cupsPermutation[selectedCup]
                print ("actualBallPosition: \(actualBallPosition). selectedBallPosition: \(selectedBallPosition)")
                ballNode.position = cupsNodes[indexOfCupWithBall].convertPosition(SCNVector3(0, 0, 0), to: self.gameNode)
                ballNode.isHidden = false
                let cupWithBall = cupsNodes[indexOfCupWithBall]
                if selectedBallPosition == actualBallPosition {
                    state = .inAction
                    AudioPlayer.shared.playSound(.success, on: sceneView.scene.rootNode)
                    let moveCupUp = SCNAction.moveBy(x: 0, y: CGFloat(0.075), z: 0, duration: 0.5)
                    cupWithBall.runAction(moveCupUp) {
                        self.levelNumber = self.levelNumber + 1
                        self.state = .next
                    }
                } else {
                    self.score = max(0, self.score - 5)
                    AudioPlayer.shared.playSound(.fail, on: sceneView.scene.rootNode)
                }
            }*/
            state = .next
        } else if state == .next {
            state = .inAction
            /*state = .inAction
            let cupWithBall = cupsNodes[indexOfCupWithBall]
            let moveCupDown = SCNAction.moveBy(x: 0, y: -CGFloat(0.075), z: 0, duration: 0.5)
            cupWithBall.runAction(moveCupDown) {
                self.run()
            }*/
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    // MARK: - ARSessionTrackingState
    
    
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
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var message: String? = nil
        
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking not available"
        case .limited(.initializing):
            message = "Initializing AR session"
        case .limited(.excessiveMotion):
            message = "Too much motion"
        case .limited(.insufficientFeatures):
            message = "Not enough surface details"
        case .limited(.relocalizing):
            message = "relocalizing"
        case .normal:
            if molecule != nil {
                if molecule!.isHidden
                {
                    message = "Move to find a horizontal surface"
                }
            }
        }
        
        message != nil ? showToast(message!) : hideToast()
    }
    
    
    func showToast(_ text: String) {
        label.text = text
        
        guard toast.alpha == 0 else {
            return
        }
        
        toast.layer.masksToBounds = true
        toast.layer.cornerRadius = 7.5
        
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 1
            self.toast.frame = self.toast.frame.insetBy(dx: -5, dy: -5)
        })
        
    }
    
    func hideToast() {
        UIView.animate(withDuration: 0.25, animations: {
            self.toast.alpha = 0
            self.toast.frame = self.toast.frame.insetBy(dx: 5, dy: 5)
        })
    }
    
    
    // MARK: - PubChem Search
    
    
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

    
    // MARK: - RCSB Search
    
    
    func didReturnPDB(pdb:[String])
    {
        print("didReturnPDB")
        UserDefaults.standard.setValue(pdb, forKey: "RecentPDB")
        
        rcsb_pdbFileArray = pdb
    }
    
    
    func didFailToReturnPubPDB(message:String, details:String)
    {
        self.didFailAlert(message:message , details:details)
    }
    

    // MARK: - Common Search
    
    
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
    
    
    @IBAction func searchAction(sender:Any)
    {
        rcsb_pdbFileArray = nil
        moleculeJSONNSDictionary = nil
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
    
    // MARK: - ARSCNViewDelegate
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        if let touchLocation = touches.first?.location(in: sceneView) {
            
            // Touch to 3D Object - fun way to snip RNA in AR space
            //if let hit = sceneView.hitTest(touchLocation, options: nil).first {
            //    hit.node.removeFromParentNode()
            //    return
            //}
            
            // Touch to Feature Point
            if let hit = sceneView.hitTest(touchLocation, types: .featurePoint).first {
                sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        //Use this method to perturb the velocity of each physics body
        // 1. need electro static attraction/repulsion - all electro bodies loop over each other
        // 2. need all hydrophobic / iso-B fields to attract - base pair stacking
        //
        // assumes rigid inole rings with swivel bonds, and corrected pi orbital representation
        
        
        
        /*
        float pos = box1.position.x;
        SCNVector3 box1Pos = box1.presentationNode.position;
        SCNVector3 box2Pos = box2.presentationNode.position;
        
        SCNVector3 delta_pos = SCNVector3Make(box2Pos.x - box1Pos.x,
                                              box2Pos.y - box1Pos.y,
                                              box2Pos.z - box1Pos.z);
        float mag = sqrt(delta_pos.x * delta_pos.x + delta_pos.y * delta_pos.y + delta_pos.z * delta_pos.z);
        SCNVector3 box1_vel = box1.physicsBody.velocity;
        SCNVector3 box2_vel = box2.physicsBody.velocity;
        if (mag > 1.0)
        {
            //box1.physicsBody.velocity = SCNVector3Make(box1_vel.x + delta_pos.x,
            //                                           box1_vel.y + delta_pos.y,
            //                                           box1_vel.z + delta_pos.z);
            #define kVelocityThreshold 0.25
            
            //needs 4 properties -- box1_vel, delta_pos, mag, kVelocityThreshold
            box1.physicsBody.velocity = SCNVector3Make( ((box1_vel.x + delta_pos.x/mag) > 0) ? MIN(box1_vel.x + delta_pos.x/mag, kVelocityThreshold) : MAX(box1_vel.x + delta_pos.x/mag, -kVelocityThreshold) ,
            ((box1_vel.y + delta_pos.y/mag) > 0) ? MIN(box1_vel.y + delta_pos.y/mag, kVelocityThreshold) : MAX(box1_vel.y + delta_pos.y/mag, -kVelocityThreshold) ,
            ((box1_vel.z + delta_pos.z/mag) > 0) ? MIN(box1_vel.z + delta_pos.z/mag, kVelocityThreshold) : MAX(box1_vel.z + delta_pos.z/mag, -kVelocityThreshold));
            
            box2.physicsBody.velocity = SCNVector3Make( ((box2_vel.x - delta_pos.x/mag) > 0) ? MIN(box2_vel.x - delta_pos.x/mag, kVelocityThreshold) : MAX(box2_vel.x - delta_pos.x/mag, -kVelocityThreshold) ,
            ((box2_vel.y - delta_pos.y/mag) > 0) ? MIN(box2_vel.y - delta_pos.y/mag, kVelocityThreshold) : MAX(box2_vel.y - delta_pos.y/mag, -kVelocityThreshold) ,
            ((box2_vel.z - delta_pos.z/mag) > 0) ? MIN(box2_vel.z - delta_pos.z/mag, kVelocityThreshold) : MAX(box2_vel.z - delta_pos.z/mag, -kVelocityThreshold));
            box1.physicsBody.angularVelocity = SCNVector4Zero;
            box2.physicsBody.angularVelocity = SCNVector4Zero;
        }
        NSLog(@"physics %f", box2_vel.x - delta_pos.x/mag);
        */
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
    }
    
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        // Create a SceneKit plane to visualize the node using its position and extent.
        
        // Create the geometry and its materials
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        //let plane = SCNPlane(width: 0.5, height: 0.5)
        
        let benchImage = UIImage(named: "Benchtop")
        let benchMaterial = SCNMaterial()
        benchMaterial.diffuse.contents = benchImage
        benchMaterial.isDoubleSided = true
        
        plane.materials = [benchMaterial]
        
        // Create a node with the plane geometry we created
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.opacity = 0.65
        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        planeNodes.append(planeNode)
        return planeNode
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        if anchor is ARPlaneAnchor {
            print("plane anchor detections")
            //molecule?.simdTransform = anchor.transform
            
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            if state == .position
            {
                createPlaneNode(anchor: planeAnchor)
            }
            self.showMessage("Plane is detected. Tap to position,\nwhere you'd like to put the game.", animated: true)
            
            return
        }
        
        
        let sceneCamPos = SCNVector3Make((sceneView.pointOfView?.position.x)!, (sceneView.pointOfView?.position.y)!, (sceneView.pointOfView?.position.z)!)
        
        print(rcsb_pdbFileArray)
        print(search_type)
        
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
    
    
    // When a detected plane is updated, make a new planeNode
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Remove existing plane nodes
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        if state == .position
        {
            let planeNode = createPlaneNode(anchor: planeAnchor)
            node.addChildNode(planeNode)
        }
    }
    
    // When a detected plane is removed, remove the planeNode
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        // Remove existing plane nodes
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
    }

    // MARK: - TableViewDelegate/Datasource
    
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
        switch self.recent_searches[indexPath.row][kSearchTypeKey] {
            case kChemical_NameSearchType?:
                self.searchField.selectedScopeButtonIndex = 0
            case kChemical_CIDSearchType?:
                self.searchField.selectedScopeButtonIndex = 1
            case kPDB_SearchType?:
                self.searchField.selectedScopeButtonIndex = 2
            default:
                print("no value")
            }
        
        self.searchAction(sender: self)
        self.searchController.isActive = false

    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchAction(sender: self)
        self.searchController.isActive = false
    }
    

    // MARK: - ReplayKit ScreenRecording
    
    
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



