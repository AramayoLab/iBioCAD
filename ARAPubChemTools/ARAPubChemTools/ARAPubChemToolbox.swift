//
//  ARAPubChemToolbox.swift
//  ARAPubChemTools
//
//  Created by Rudy Aramayo on 1/27/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import SceneKit
//import ARACoreUtils

public protocol ARAPubChemMoleculeSearchDelegate {
    func didReturnPubChemMolecule(moleculeNode:NSDictionary)
    func didFailToReturnPubChemMolecule(message:String, details:String)
}



public class ARAPubChemToolbox: NSObject {

    public var delegate:ARAPubChemMoleculeSearchDelegate!
    public var loaded_molecule:SCNNode?
    
    public func initToolbox(search_delegate:ARAPubChemMoleculeSearchDelegate) {
        self.delegate = search_delegate
    }
    
    
    public func pubChem_compoundSearchByName(searchTerm:String, record_type_3d:Bool)
    {
        if (searchTerm != "")
        {
            var threeD = ""
            if record_type_3d == true
            {
                threeD = "record_type=3d"
            }
            let url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/" + searchTerm.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "/JSON?" + threeD
            self.getJsonFromUrl(urlString: url)
        }
        else
        {
            delegate.didFailToReturnPubChemMolecule(message: "Empty Search", details: "")
        }
    }
    
    
    public func pubChem_compoudSearchByCID(searchTerm:String, record_type_3d:Bool)
    {
        if (searchTerm != "")
        {
            var threeD = ""
            if record_type_3d == true
            {
                threeD = "record_type=3d"
            }
            let url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/" + searchTerm + "/JSON?" + threeD
            self.getJsonFromUrl(urlString: url)
        }
        else
        {
            delegate.didFailToReturnPubChemMolecule(message: "Empty Search", details: "")
        }
    }
    
    
    public func pubChem_didReturnNetworkResultForCIDSearch(jsonResponse:NSDictionary)
    {
        print("pubChem_didReturnNetworkResultForCIDSearch")
        self.delegate.didReturnPubChemMolecule(moleculeNode: jsonResponse)
    }
    
    
    public func getJsonFromUrl(urlString:String){
        
        let url = URL(string: urlString)
        print(urlString)
        print(url)
        URLSession.shared.dataTask(with: (url as? URL)!, completionHandler: {(data, response, error) -> Void in
            
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                
                if let fault = jsonObj!.value(forKey: "Fault")
                {
                    print(fault)
                    let faultDict = fault as! NSDictionary
                    DispatchQueue.main.async {
                            print(faultDict.value(forKey: "Message") as! String)
                            print((faultDict.value(forKey: "Details") as! NSArray)[0] as! String)
                            
                            self.delegate.didFailToReturnPubChemMolecule(message:faultDict.value(forKey: "Message") as! String,
                                                                    details:(faultDict.value(forKey: "Details") as! NSArray)[0] as! String)
                    }
                    return
                }
                
                OperationQueue.main.addOperation({
                    self.pubChem_didReturnNetworkResultForCIDSearch(jsonResponse:jsonObj!)
                })
            }
        }).resume()
        
        
    }
    
    
    
    public func printPubChemMoleculeProperties(jsonResponse:NSDictionary)
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
    
    
    public func loadPubChemMolecule( jsonResponse:NSDictionary, targetScene:SCNScene, targetNode:SCNNode, targetPosition:SCNVector3)
    {
        var molecule: SCNNode = SCNNode()
        print(jsonResponse.value(forKey: "PC_Compounds")!)

        #if os(OSX)
            let atomicVertexToARCorrectionFactor:CGFloat = 1
        #elseif os(iOS)
            let atomicVertexToARCorrectionFactor:Float = 0.1
        #endif
        
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
        
        //print(orderArray)
        
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
                        #if os(OSX)
                            coord_scnVec = SCNVector3Make(xArray[i] as! CGFloat, yArray[i] as! CGFloat, zArray[i] as! CGFloat)
                        #elseif os(iOS)
                            //coord_scnVec = SCNVector3Make(xArray[i] as! Float, yArray[i] as! Float, zArray[i] as! Float)
                        coord_scnVec = SCNVector3Make((xArray[i] as! NSNumber).floatValue,
                                                      (yArray[i] as! NSNumber).floatValue,
                                                      (zArray[i] as! NSNumber).floatValue)
                        #endif
                    }
                    else
                    {
                        #if os(OSX)
                            coord_scnVec = SCNVector3Make(xArray[i] as! CGFloat, yArray[i] as! CGFloat, 0.0)
                        #elseif os(iOS)
                            coord_scnVec = SCNVector3Make((xArray[i] as! NSNumber).floatValue,
                                                          (yArray[i] as! NSNumber).floatValue,
                                                          0.0)
                        
                            //coord_scnVec = SCNVector3Make(Float(xArray[i] as! Double), Float(yArray[i] as! Double), 0.0)
                        #endif
                    }
                    
                    
                    //let order = orderArray[i]
                    
                    print("aid", aid)
                    print("element", element)
                    print("coord_scnVec", coord_scnVec)
                    //print("order", order)
                    
                    #if os(OSX)
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
                            atom_color = NSColor.darkGray;
                            break;
                        }
                        
                    #elseif os(iOS)
                        var atom_color = UIColor.white
                        
                        switch element
                        {
                        case 1: //Hydrogen
                            atom_color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                            break;
                        case 8: //Oxygen
                            atom_color = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
                            break;
                        case 7: //Nitrogen
                            atom_color = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
                            break;
                        case 6: //Carbon
                            atom_color = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
                            break;
                        case 15: //Phosphorus
                            atom_color = UIColor(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0)
                            break;
                        case 11: //Sodium
                            atom_color = UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0)
                            break;
                        case 12: //Magnesium
                            atom_color = UIColor(red: 0.2, green: 1.0, blue: 0.0, alpha: 1.0)
                            break;
                        case 19: //Potassium
                            atom_color = UIColor(red: 0.23, green: 0.8, blue: 0.51, alpha: 1.0)
                            break;
                        case 20: //Calcium
                            atom_color = UIColor(red: 0.2, green: 0.87, blue: 0.0, alpha: 1.0)
                            break;
                        case 16: //Sulpher
                            atom_color = UIColor(red: 0.83, green: 0.87, blue: 0.0, alpha: 1.0)
                            break;
                        case 17: //Chloride
                            atom_color = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
                            break;
                        case 26: //Iron
                            atom_color = UIColor(red: 0.64, green: 0.32, blue: 0.0, alpha: 1.0)
                            break;
                        case 9: //Florine
                            atom_color = UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
                            break;
                        default:
                            atom_color = UIColor.darkGray;
                            break;
                        }
                        
                    #endif
                    
                    print(atom_color)
                    
                    geometryAtoms.add(atomDict)
                    geometryAtomsCoordArray.add(coord_scnVec)
                    geometryElements.add(element)
                    //geometryOrderArray.add(order)//can't add this... there may be solo atoms
                    
                    
                    let sphere = SCNSphere(radius: (getAtomSize_vanderwalls(element:element)/4.0 ) * CGFloat(atomicVertexToARCorrectionFactor) )
                    
                    sphere.segmentCount = 4;
                    sphere.firstMaterial?.diffuse.contents = atom_color;
                    let sphereNode = SCNNode(geometry: sphere)
                    sphereNode.physicsBody = .dynamic()
                    sphereNode.name = String(describing: aid)
                    
                    
                    
                    if (zArrayIndicies)
                    {
                        #if os(OSX)
                            sphereNode.position = SCNVector3(x: (xArray[i] as! CGFloat) * atomicVertexToARCorrectionFactor,
                                                             y: (yArray[i] as! CGFloat) * atomicVertexToARCorrectionFactor,
                                                             z: (zArray[i] as! CGFloat) * atomicVertexToARCorrectionFactor)
                        #elseif os(iOS)
                            sphereNode.position = SCNVector3Make((xArray[i] as! NSNumber).floatValue * atomicVertexToARCorrectionFactor,
                                                      (yArray[i] as! NSNumber).floatValue * atomicVertexToARCorrectionFactor,
                                                      (zArray[i] as! NSNumber).floatValue * atomicVertexToARCorrectionFactor)
                            
                        #endif
                        
                        
                    }
                    else
                    {
                        #if os(OSX)
                            sphereNode.position = SCNVector3(x: (xArray[i] as! CGFloat) * atomicVertexToARCorrectionFactor,
                                                             y: (yArray[i] as! CGFloat) * atomicVertexToARCorrectionFactor,
                                                             z: 0.00001*CGFloat(i)) //Gives the 2d stuff some 3dness so it doesn't stop calculating third dimension
                        #elseif os(iOS)
                            sphereNode.position = SCNVector3Make((xArray[i] as! NSNumber).floatValue * atomicVertexToARCorrectionFactor,
                                                                 (yArray[i] as! NSNumber).floatValue * atomicVertexToARCorrectionFactor,
                                                                 0.00001*Float(i)) //Gives the 2d stuff some 3dness so it doesn't stop calculating third dimension
                        #endif
                        
                        
                    }
                    
                    molecule.addChildNode(sphereNode)
                    
                    i = i+1
                    
                }
            }
        }
        
        // before making bonds, bind all pi orbitals and organic rings rigidly...
        // allow static pi orbital formations according to the strength of the pKA delta from iso-physio ph
        // sites of H acid are like pKa of 4.0 so at 7.0 iso-physiological ph you see a strength
        // of delta 3.0 to keep a pi orbital system... that is the strength of the e– lone pair region
        // that strength translates into the pull it has or binding to other + areas/ Mg2+/Zn2+ ions
        
        
        
        var i=0
        
        for _ in bonds_aid1_Array
        {
            
            print("bonds_aid1_Array ", bonds_aid1_Array[i])
            print("bonds_aid2_Array ", bonds_aid2_Array[i])
            print("orderArray ", orderArray[i])
            
            
            // WE subtract 1 from the AID because it starts at 1 -> maxAtoms (795 for the RNA) and index out of bounds will be thrown otherwise
            let element1 = elementArray[(bonds_aid1_Array[i] as! Int) - 1] as! Int
            let element2 = elementArray[(bonds_aid2_Array[i] as! Int) - 1] as! Int
            var bondOrder = orderArray[i] as! Int
            
            if element1 == 6 && element2 == 6
            {
                bondOrder = 2
            }
            let aid1 = molecule.childNode(withName: String(describing:bonds_aid1_Array[i]), recursively: true) as! SCNNode
            let aid2 = molecule.childNode(withName: String(describing:bonds_aid2_Array[i]), recursively: true) as! SCNNode
            
            /*
             let x1 = xArray[bonds_aid1_Array[i] as! Int] as! CGFloat
             let y1 = yArray[bonds_aid1_Array[i] as! Int] as! CGFloat
             let z1 = zArray[bonds_aid1_Array[i] as! Int] as! CGFloat
             
             let x2 = xArray[bonds_aid2_Array[i] as! Int] as! CGFloat
             let y2 = yArray[bonds_aid2_Array[i] as! Int] as! CGFloat
             let z2 = zArray[bonds_aid2_Array[i] as! Int] as! CGFloat
             */
            
            //let scnView = self.view as! SCNView
            
            
            if (bondOrder == 1 )
            {
                //1st Order
                let bond_joint = SCNPhysicsBallSocketJoint(bodyA: aid1.physicsBody!,
                                                           anchorA: SCNVector3Make(-0.15 * atomicVertexToARCorrectionFactor, 0, 0),
                                                           bodyB: aid2.physicsBody!,
                                                           anchorB: SCNVector3Make(0.15 * atomicVertexToARCorrectionFactor, 0, 0))
                targetScene.physicsWorld.addBehavior(bond_joint)
            }
            
            if (bondOrder == 2 )
            {
                //2nd order
                let bond_joint = SCNPhysicsHingeJoint.init(bodyA: aid1.physicsBody!,
                                                           axisA: SCNVector3Make(0, 0, 1),
                                                           anchorA: SCNVector3Make(-0.55 * atomicVertexToARCorrectionFactor, 0, 0),
                                                           bodyB: aid2.physicsBody!,
                                                           axisB: SCNVector3Make(0, 0, 1),
                                                           anchorB: SCNVector3Make(0.55 * atomicVertexToARCorrectionFactor, 0, 0))
                
                targetScene.physicsWorld.addBehavior(bond_joint)
                
            }
            
            if (bondOrder == 3 )
            {
                //2nd order
                let bond_joint = SCNPhysicsConeTwistJoint(bodyA: aid1.physicsBody!,
                                                          frameA: SCNMatrix4Identity,
                                                          bodyB: aid2.physicsBody!,
                                                          frameB: SCNMatrix4Identity)
 
                
                targetScene.physicsWorld.addBehavior(bond_joint)
                
            }
            
            i = i+1
        }
        
        centerAtoms(molecule: molecule)
        molecule.position = targetPosition
        targetScene.rootNode.addChildNode(molecule)
    }
    
    
    public func getAtomSize_vanderwalls(element: Int) -> CGFloat
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
    
    func centerAtoms(molecule:SCNNode)
    {
        var average_vec: SCNVector3 = SCNVector3Zero
        
        for atom in molecule.childNodes
        {
            average_vec.x = average_vec.x + atom.position.x
            average_vec.y = average_vec.y + atom.position.y
            average_vec.z = average_vec.z + atom.position.z
        }
        #if os(OSX)
            let count = CGFloat(molecule.childNodes.count)
        #elseif os(iOS)
            let count = Float(molecule.childNodes.count)
        #endif
        
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
    
}
