//
//  ARA_RCSBToolbox.swift
//  ARA_RCSBTools
//
//  Created by Rudy Aramayo on 2/2/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import Foundation
import SceneKit


public protocol ARA_RCSB_PDBSearchDelegate {
    func didReturnPDB(pdb:[String])
    func didFailToReturnPubPDB(message:String, details:String)
}


public class ARA_RCSBToolbox: NSObject {

    public var delegate:ARA_RCSB_PDBSearchDelegate!

    #if os(OSX)
    let atomicVertexToARCorrectionFactor:CGFloat = 1
    #elseif os(iOS)
    let atomicVertexToARCorrectionFactor:Float = 0.01
    #endif
    
    public func initToolbox(search_delegate:ARA_RCSB_PDBSearchDelegate) {
        self.delegate = search_delegate
    }
    
    
    public class func printme_imdelicate()
    {
        print("SaveBioScript")
    }
    
    
    public func rcsb_pdbSearchByID(searchTerm:String)
    {
        if (searchTerm != "")
        {
            let url = "https://files.rcsb.org/download/" + searchTerm + ".pdb"
            self.getDataFromUrl(urlString: url) { (data, response, error ) in
                
                let x = String.init(data:data!, encoding:.utf8)
                let pdbArray = x!.components(separatedBy: "\n")

                //return data to the delegate ... only parse in the other loop
                if (pdbArray[0].starts(with: "<!DOCTYPE HTML PUBLIC"))
                {
                    self.delegate.didFailToReturnPubPDB(message: "PDB Not Found", details: "")
                    return
                }
                self.delegate.didReturnPDB(pdb: pdbArray)
            }
        }
        else
        {
            delegate.didFailToReturnPubPDB(message: "Empty Search", details: "")
        }
    }
    
    public func loadPDBJsonMolecule( pdbArray:[String], targetScene:SCNScene, targetNode:SCNNode, targetPosition:SCNVector3)
    {
        var molecule: SCNNode = SCNNode()
        
        
        for pdb_entry in pdbArray
        {
            if (pdb_entry != "")
            {
                let entry_type = String(pdb_entry[0...5])
                
                switch (entry_type)
                {
                    case "ATOM  ":
                        self.parseAtom(pdb_entry: pdb_entry, molecule: molecule)
                    case "HETATM":
                        self.parseAtom(pdb_entry: pdb_entry, molecule: molecule)
                    default:
                        print("CouldNotParse - " + entry_type)
                }
            }
        }
        
        for childNode in molecule.childNodes
        {
            
        }
        
        //Loop Bonds
        /*
    
        // WE subtract 1 from the AID because it starts at 1 -> maxAtoms (795 for the RNA) and index out of bounds will be thrown otherwise
        let element1 = elementArray[(bonds_aid1_Array[i] as! Int) - 1] as! Int
        let element2 = elementArray[(bonds_aid2_Array[i] as! Int) - 1] as! Int
        let bondOrder = orderArray[i] as! Int
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
            /*let bond_joint = SCNPhysicsConeTwistJoint(bodyA: aid1.physicsBody!,
             frameA: SCNMatrix4Identity,
             bodyB: aid2.physicsBody!,
             frameB: SCNMatrix4Identity)
             */
            let bond_joint = SCNPhysicsHingeJoint.init(bodyA: aid1.physicsBody!,
                                                       axisA: SCNVector3Make(0, 0, 1),
                                                       anchorA: SCNVector3Make(-0.45 * atomicVertexToARCorrectionFactor, 0, 0),
                                                       bodyB: aid2.physicsBody!,
                                                       axisB: SCNVector3Make(0, 0, 1),
                                                       anchorB: SCNVector3Make(0.45 * atomicVertexToARCorrectionFactor, 0, 0))
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
        
 
        centerAtoms(molecule: molecule)
         */
        
        molecule.position = targetPosition

        
        ARACoreUtils.centerAtoms(molecule: molecule)

        targetScene.rootNode.addChildNode(molecule)
    }

    
    func parseAtom(pdb_entry:String, molecule:SCNNode)
    {

        //ATOM entry properties
        let atom_id = String(pdb_entry[0...5]).replacingOccurrences(of:" ", with: "")
        let atom_name = String(pdb_entry[6...10]).replacingOccurrences(of:" ", with: "")
        let atom_char = String(pdb_entry[12...15]).replacingOccurrences(of:" ", with: "")
        let atom_residue_name = String(pdb_entry[17...19]).replacingOccurrences(of:" ", with: "")
        let atom_chain_id = String(pdb_entry[21...21]).replacingOccurrences(of:" ", with: "")
        let atom_residue_sequence_id = String(pdb_entry[22...25]).replacingOccurrences(of:" ", with: "")
        let atom_iCode = String(pdb_entry[26...26]).replacingOccurrences(of:" ", with: "")
        let atom_x = String(pdb_entry[30...37]).replacingOccurrences(of:" ", with: "")
        let atom_y = String(pdb_entry[38...45]).replacingOccurrences(of:" ", with: "")
        let atom_z = String(pdb_entry[46...53]).replacingOccurrences(of:" ", with: "")
        let atom_occupancy = String(pdb_entry[54...59]).replacingOccurrences(of:" ", with: "")
        let atom_tempFactor = String(pdb_entry[60...65]).replacingOccurrences(of:" ", with: "")
        let atom_element = String(pdb_entry[76...77]).replacingOccurrences(of:" ", with: "")
        let atom_charge = String(pdb_entry[78...79]).replacingOccurrences(of:" ", with: "")
        
        //ATOM 52 NH1BARG A -3    14.338 86.056 88.706 0.50 40.23 N
        
        let element_int:Int = ARACoreUtils.periodic_table_element_for_string(element: atom_element)
        
        
        print(atom_id)
        print(atom_name)
        print(atom_char)
        print(atom_residue_name)
        print(atom_chain_id)
        print(atom_residue_sequence_id)
        print(atom_iCode)
        print(atom_x)
        print(atom_y)
        print(atom_z)
        print(atom_occupancy)
        print(atom_tempFactor)
        print(atom_element)
        print(atom_charge)
        
        switch atom_residue_name {
            case "A":
                print("Adenine")
            case "T":
                print("Thymine")
            case "U":
                print("Uracil")
            case "C":
                print("Cytosine")
            case "G":
                print("Guanine")
            
            default:
                print("*** unknown ***")
        }
        
        var coord_scnVec:SCNVector3
        
        #if os(OSX)
            coord_scnVec = SCNVector3Make(CGFloat(Float(atom_x)!), CGFloat(Float(atom_y)!), CGFloat(Float(atom_z)!))
        #elseif os(iOS)
            coord_scnVec = SCNVector3Make(Float(atom_x)!, Float(atom_y)!, Float(atom_z)!)
        #endif
        
        let sphere = SCNSphere(radius: ARACoreUtils.getAtomSize_vanderwalls(element: element_int) * CGFloat(atomicVertexToARCorrectionFactor) )
        
        sphere.segmentCount = 4;
        sphere.firstMaterial?.diffuse.contents = ARACoreUtils.getAtom_color(element:element_int)
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.physicsBody = .dynamic()
        sphereNode.name = String(describing: atom_id)
        sphereNode.position = SCNVector3(x: coord_scnVec.x * atomicVertexToARCorrectionFactor,
                                         y: coord_scnVec.y * atomicVertexToARCorrectionFactor,
                                         z: coord_scnVec.z * atomicVertexToARCorrectionFactor)
        
        molecule.addChildNode(sphereNode)
    }
    
    
    
    
    
    
    func getDataFromUrl(urlString: String, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        let url = URL(string: urlString)

        URLSession.shared.dataTask(with: url!) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    
}


extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
