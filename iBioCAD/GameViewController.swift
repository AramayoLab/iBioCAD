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


class GameViewController: NSViewController, ARAPubChemMoleculeSearchDelegate {
    
    var rna: SCNNode?
    var average_vec:SCNVector3 = SCNVector3Zero
    var molecule:SCNNode?

    func centerAtoms(molecule:SCNNode)
    {
        for atom in molecule.childNodes
        {
            average_vec.x = average_vec.x + atom.position.x
            average_vec.y = average_vec.y + atom.position.y
            average_vec.z = average_vec.z + atom.position.z
        }
        
        let count = CGFloat(molecule.childNodes.count)
        
        average_vec.x = average_vec.x / count
        average_vec.y = average_vec.y / count
        average_vec.z = average_vec.z / count
        
        for atom in molecule.childNodes
        {
            atom.position = SCNVector3Make(atom.position.x - average_vec.x,
                                           atom.position.y - average_vec.y,
                                           atom.position.z - average_vec.z)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene(named: "BenzeneReaction1.scn")!
        rna = SCNNode()
        
        rna?.position = SCNVector3(0,0,0)
        
        scene.rootNode.addChildNode(rna!)
        scene.physicsWorld.speed = 0.1;
        
        
        
        
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
    
    
    func didReturnPubChemMolecule(moleculeNode:SCNNode)
    {
        print("didReturnPubChemMolecule")
        print(moleculeNode)
        molecule = moleculeNode
        molecule?.removeFromParentNode()
        molecule!.position = SCNVector3Make(0, 0, 0)
        let scnView = self.view as! SCNView
        scnView.scene?.rootNode.addChildNode(molecule!)
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
    
    
    func pubChem_compoudSearchByCID(searchTerm:String, record_type:String)
    {
        var threeD = ""
        if record_type == "3d"
        {
            threeD = "record_type=3d"
        }
        let url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/" + searchTerm + "/JSON?" + threeD
        self.getJsonFromUrl(urlString: url)
    }
    
    
    func pubChem_compoundSearchByName(searchTerm:String, record_type:String)
    {
        var threeD = ""
        if record_type == "3d"
        {
            threeD = "record_type=3d"
        }
        let url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/" + searchTerm + "/JSON?" + threeD
        self.getJsonFromUrl(urlString: url)
    }
    
    
    func pubChem_didReturnNetworkResultForCIDSearch(jsonResponse:NSDictionary)
    {
        print("pubChem_didReturnNetworkResultForCIDSearch")
        //loadPubChemMoleculeProperties( string:jsonResponse.PC_Compounds[0].id.id.cid);
        //loadPubChemMolecule( string:jsonResponse.PC_Compounds[0]);
        
        self.loadPubChemMolecule(jsonResponse: jsonResponse)
        self.printPubChemMoleculeProperties(jsonResponse: jsonResponse)
        
    }
    
    
    //this function is fetching the json from URL
    func getJsonFromUrl(urlString:String){
        //creating a NSURL
        let url = URL(string: urlString)
        
        //fetching the data from the url
        URLSession.shared.dataTask(with: (url)!, completionHandler: {(data, response, error) -> Void in
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                
                //printing the json in console
                //print(jsonObj!)
                
                if let fault = jsonObj!.value(forKey: "Fault")
                {
                    print(fault)
                    
                    let faultDict = fault as! NSDictionary
                    
                    
                    DispatchQueue.main.async {
                        
                        let alert: NSAlert = NSAlert()
                        alert.messageText = faultDict.value(forKey: "Message") as! String
                        
                        
                        print(faultDict.value(forKey: "Details") as! NSArray)
                        
                        alert.informativeText = (faultDict.value(forKey: "Details") as! NSArray)[0] as! String
                        alert.alertStyle = NSAlert.Style.warning
                        alert.addButton(withTitle: "OK")
                        alert.addButton(withTitle: "Cancel")
                        let res = alert.runModal()
                        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
                            return
                        }
                        
                    }
                    
                    return
                }
                //Example of adding an operation after this data is completely fetched from the server
                OperationQueue.main.addOperation({
                    //calling another function after fetching the json
                    //it will show the names to label
                    self.pubChem_didReturnNetworkResultForCIDSearch(jsonResponse:jsonObj!)
                })
            }
        }).resume()
        
        
    }
    
    
    
    func printPubChemMoleculeProperties(jsonResponse:NSDictionary)
    {
        print(jsonResponse)
        print(jsonResponse.value(forKey: "PC_Compounds")!)
        
        let propertyArray = (jsonResponse.value(forKey:"PC_Compounds")! as AnyObject).value(forKey:"props") as! NSArray

        print(propertyArray)
        
        let propertyArray2 = propertyArray.object(at: 0) as! NSArray
        
        for prop in propertyArray2
        {
            let urn = (prop as! NSDictionary).value(forKey:"urn") as! NSDictionary
            print(urn)
            
            var label = ""
            if (urn.value(forKey:"label") != nil)
            {
                label = urn.value(forKey:"label") as! String
            }
            print(label)
            
            var urn_name = ""
            if (urn.value(forKey:"name") != nil)
            {
                urn_name = urn.value(forKey:"name") as! String
            }
            print(urn_name)
            
            let urn_value = (prop as! NSDictionary).value(forKey:"value") as! NSDictionary
            print(urn_value)
            
            switch label
            {
                case "InChI":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "InChIKey":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Log P":
                    print (urn_name, "+", urn_value)
                    
                    break;
                
                case "Fingerprint":
                    print (urn_name, "+", urn_value)
                    
                    break;
                
                case "SMILES":
                    print (urn_name, "+", urn_value)
                    
                    break;
                
                case "Topological":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Count":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "_Count":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "IUPAC Name":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Weight":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Molecular Weight":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Mass":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Molecular Formula":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Compound":
                    print (urn_name, "+", urn_value)
                    
                    break;
                case "Compound Complexity":
                    print (urn_name, "+", urn_value)
                    
                    break;
                
                
            default:
                print("error in parsing:", urn)
                break;
                
            }
            
        }
    
    }
    
    
    func loadPubChemMolecule( jsonResponse:NSDictionary )
    {
        //print(jsonResponse)
        print(jsonResponse.value(forKey: "PC_Compounds")!)
        
        
        //loader.pubChem_load( pubChem_3djson, function ( geometry, geometryBonds, order ) {
        
        var geometryAtoms = [] as NSMutableArray
        var geometryAtomsCoordArray = [] as NSMutableArray
        var geometryBonds = [] as NSMutableArray
        var geometryElements = [] as NSMutableArray
        var geometryOrderArray = [] as NSMutableArray
        
        
        let atomsArray = (jsonResponse.value(forKey:"PC_Compounds")! as AnyObject).value(forKey:"atoms") as! NSArray
        print(atomsArray)
        let bondsArray = (jsonResponse.value(forKey:"PC_Compounds")! as AnyObject).value(forKey:"bonds") as! NSArray
        let bonds_aid1_Array = (bondsArray.value(forKey:"aid1") as! NSArray)[0] as! NSArray
        let bonds_aid2_Array = (bondsArray.value(forKey:"aid2") as! NSArray)[0] as! NSArray
        print(bondsArray)
        print(bonds_aid1_Array)
        print(bonds_aid2_Array)
        
        let coordsArray = (jsonResponse.value(forKey:"PC_Compounds")! as AnyObject).value(forKey:"coords") as! NSArray
        let coords_aid_Array = coordsArray.value(forKey:"aid") as! NSArray
        let coords_conformers_Array = coordsArray.value(forKey:"conformers") as! NSArray
        print(coordsArray)
        print(coords_aid_Array)
        print(coords_conformers_Array)
        
        
        
        let propsArray = (jsonResponse.value(forKey:"PC_Compounds")! as AnyObject).value(forKey:"props") as! NSArray
        print(propsArray)
        let firstPropertyDictionary = (propsArray[0] as! NSArray)[0] as! NSDictionary
        print(firstPropertyDictionary)
        let firstPropertyUrn = firstPropertyDictionary.value(forKey: "urn") as! NSDictionary
        print(firstPropertyUrn)
        let firstPropertyValue = firstPropertyDictionary.value(forKey: "value") as! NSDictionary
        print(firstPropertyValue)
        
        
        
        
        var orderArray = bondsArray.value(forKey:"order") as! NSArray
        orderArray = orderArray[0] as! NSArray
        
        print(orderArray)
        
        var aidArray:NSArray = []
        var elementArray:NSArray = []
        
        var xArray:NSArray = []
        var yArray:NSArray = []
        var zArray:NSArray = []
        
        for atom in atomsArray {
            //converting the element to a dictionary
            if let atomDict = atom as? NSDictionary {
                
                //getting the name from the dictionary
                aidArray = atomDict.value(forKey: "aid") as! NSArray
                elementArray = atomDict.value(forKey: "element") as! NSArray
                
                var i=0
                for aid in aidArray
                {
                    let element = elementArray[i] as! Int
                    let coord = ((coords_conformers_Array[0] as! NSArray)[0] as! NSArray)
                    let coordDict = coord[0] as! NSDictionary
                    
                    //Array of all atomic coords to be matched 12 atoms = 12 entries in xArray
                    xArray = coordDict.value(forKey: "x") as! NSArray
                    yArray = coordDict.value(forKey: "y") as! NSArray
                    
                    var zArrayIndicies:Bool = false
                    
                    zArray = []
                    
                    if (coordDict.value(forKey: "z") != nil)
                    {
                        zArray = coordDict.value(forKey: "z") as! NSArray
                        zArrayIndicies = true
                    }
                    
                    var coord_scnVec:SCNVector3
                    
                    if (zArrayIndicies)
                    {
                        coord_scnVec = SCNVector3Make(xArray[i] as! CGFloat, yArray[i] as! CGFloat, zArray[i] as! CGFloat)
                    }
                    else
                    {
                        coord_scnVec = SCNVector3Make(xArray[i] as! CGFloat, yArray[i] as! CGFloat, 0.0)
                    }
                    
                    
                    let order = orderArray[i]
                    
                    print("aid", aid)
                    print("element", element)
                    print("coord_scnVec", coord_scnVec)
                    print("order", order)
                    
                    
                    var atom_color = NSColor.white
                    
                    switch element
                    {
                        case 1: //Hydrogen
                            atom_color = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                            break;
                        case 8: //Oxygen
                            atom_color = NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
                            break;
                        case 7: //Nitrogen
                            atom_color = NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
                            break;
                        case 6: //Carbon
                            atom_color = NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
                            break;
                        case 15: //Phosphorus
                            atom_color = NSColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0)
                            break;
                        case 11: //Sodium
                            atom_color = NSColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0)
                            break;
                        case 12: //Magnesium
                            atom_color = NSColor(red: 0.2, green: 1.0, blue: 0.0, alpha: 1.0)
                            break;
                        case 19: //Potassium
                            atom_color = NSColor(red: 0.23, green: 0.8, blue: 0.51, alpha: 1.0)
                            break;
                        case 20: //Calcium
                            atom_color = NSColor(red: 0.2, green: 0.87, blue: 0.0, alpha: 1.0)
                            break;
                        case 16: //Sulpher
                            atom_color = NSColor(red: 0.83, green: 0.87, blue: 0.0, alpha: 1.0)
                            break;
                        case 17: //Chloride
                            atom_color = NSColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
                            break;
                        case 26: //Iron
                            atom_color = NSColor(red: 0.64, green: 0.32, blue: 0.0, alpha: 1.0)
                            break;
                        case 9: //Florine
                            atom_color = NSColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
                            break;
                        default:
                            atom_color = NSColor.gridColor;
                            break;
                    }
                    
                    print(atom_color)
                    
                    geometryAtoms.add(atomDict)
                    geometryAtomsCoordArray.add(coord_scnVec)
                    geometryElements.add(element)
                    geometryOrderArray.add(order)
                    
                    
                    let sphere = SCNSphere(radius: getAtomSize_vanderwalls(element:element)/4.0)
                    
                    sphere.segmentCount = 4;
                    sphere.firstMaterial?.diffuse.contents = atom_color;
                    let sphereNode = SCNNode(geometry: sphere)
                    sphereNode.physicsBody = .dynamic()
                    sphereNode.name = String(describing: aid)
                    
                    
                    if (zArrayIndicies)
                    {
                        sphereNode.position = SCNVector3(x: xArray[i] as! CGFloat,
                                                         y: yArray[i] as! CGFloat,
                                                         z: zArray[i] as! CGFloat)
                        
                    }
                    else
                    {
                        sphereNode.position = SCNVector3(x: xArray[i] as! CGFloat,
                                                         y: yArray[i] as! CGFloat,
                                                         z: 0.00001*CGFloat(i)) //Gives the 2d stuff some 3dness so it doesn't stop calculating third dimension
                        
                    }
                    
                    
                    
                    //print(sphereNode)
                    
                    //let scnView = self.view as! SCNView
                    rna!.addChildNode(sphereNode)
                    
                    i = i+1
                    
                }
            }
        }
        
        
        var i=0
        
        for _ in bonds_aid1_Array
        {
            
            if i == 795
            {
                print("break")
            }
            
            
            print("bonds_aid1_Array ", bonds_aid1_Array[i])
            print("bonds_aid2_Array ", bonds_aid2_Array[i])
            print("orderArray ", orderArray[i])
            
            
            // WE subtract 1 from the AID because it starts at 1 -> maxAtoms (795 for the RNA) and index out of bounds will be thrown otherwise
            let element1 = elementArray[(bonds_aid1_Array[i] as! Int) - 1] as! Int
            let element2 = elementArray[(bonds_aid2_Array[i] as! Int) - 1] as! Int
            let bondOrder = orderArray[i] as! Int
            let aid1 = rna?.childNode(withName: String(describing:bonds_aid1_Array[i]), recursively: true) as! SCNNode
            let aid2 = rna?.childNode(withName: String(describing:bonds_aid2_Array[i]), recursively: true) as! SCNNode

            /*
            let x1 = xArray[bonds_aid1_Array[i] as! Int] as! CGFloat
            let y1 = yArray[bonds_aid1_Array[i] as! Int] as! CGFloat
            let z1 = zArray[bonds_aid1_Array[i] as! Int] as! CGFloat
            
            let x2 = xArray[bonds_aid2_Array[i] as! Int] as! CGFloat
            let y2 = yArray[bonds_aid2_Array[i] as! Int] as! CGFloat
            let z2 = zArray[bonds_aid2_Array[i] as! Int] as! CGFloat
            */
            
            let scnView = self.view as! SCNView

            /*
            //if (bondOrder == 1 )
            //{
                //1st Order
                let bond_joint = SCNPhysicsBallSocketJoint(bodyA: aid1.physicsBody!,
                                                           anchorA: SCNVector3Make(-0.25, 0, 0),
                                                           bodyB: aid2.physicsBody!,
                                                           anchorB: SCNVector3Make(0.25, 0, 0))
                scnView.scene?.physicsWorld.addBehavior(bond_joint)
            ///}
 */
            
            //if (bondOrder == 2 )
            //{
                //2nd order
            
                //2nd order
                let bond_joint_cone_twist = SCNPhysicsConeTwistJoint(bodyA: aid1.physicsBody!,
                                                         frameA: SCNMatrix4Identity,
                                                          bodyB: aid2.physicsBody!,
                                                         frameB: SCNMatrix4Identity)
                bond_joint_cone_twist.maximumTwistAngle = 0;
                bond_joint_cone_twist.maximumAngularLimit1 = 0;
                bond_joint_cone_twist.maximumAngularLimit2 = 0;
                
                
                let bond_joint = SCNPhysicsHingeJoint.init(bodyA: aid1.physicsBody!,
                                      axisA: SCNVector3Make(0, 0, 1),
                                      anchorA: SCNVector3Make(-0.25, 0, 0),
                                      bodyB: aid2.physicsBody!,
                                      axisB: SCNVector3Make(0, 0, 1),
                                      anchorB: SCNVector3Make(0.25, 0, 0))
                scnView.scene?.physicsWorld.addBehavior(bond_joint)

            //}
            
            i = i+1
 
        }
        
        centerAtoms(molecule: rna!)
    }
    
 
    func getAtomSize_vanderwalls(element: Int) -> CGFloat
    {
        print("element -", element)
        switch(element)
        {
            case 6:
                print("carbon")
                return 170/200.0//attometers
            case 8:
                print("oxygen")
                return 152/200.0//attometers
            case 7:
                print("nitrogen")
                return 155/200.0//attometers
            case 1:
                print("hydrogen")
                return 120/200.0//attometers
            default:
                return 100.0/200.0//attometers
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

        /*
         //FILEBUG: why adding the physics properties is so tricky? I don't see any of them implemented properly with this framework on OSX but it works on iOS
        let t = ARAPubChemToolbox()
        t.initToolbox(search_delegate: self, new_scene: scnView.scene!)
        //t.pubChem_compoundSearchByName(searchTerm: "benzene", record_type_3d: true)
        t.pubChem_compoudSearchByCID(searchTerm: "86583373", record_type_3d:false)
 
        return
        */
        
        self.pubChem_compoundSearchByName(searchTerm:"benzene", record_type: "3d") //Make sure to look up a broken gvalue here for robustness and replace ! with ?
        //self.pubChem_compoudSearchByCID(searchTerm:"86583373", record_type: "") //some 2d RNA with no conformer
        //self.pubChem_compoudSearchByCID(searchTerm:"16197306", record_type: "") //some 2d DNA with no conformer
        //self.pubChem_compoudSearchByCID(searchTerm:"11979623", record_type: "") //some 2d Double strand of RNA with no conformer
        
        
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
