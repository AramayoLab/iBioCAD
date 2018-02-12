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
    let atomicVertexToARCorrectionFactor:Float = 1
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
        var atoms:[ARA_PDBAtom] = []
        var hetatoms:[ARA_PDBAtom] = []
        
        for pdb_entry in pdbArray
        {
            if (pdb_entry != "")
            {
                let entry_type = String(pdb_entry[0...5])
                
                switch (entry_type)
                {
                    case "ATOM  ":
                        atoms.append(self.parseAtom(pdb_entry: pdb_entry, molecule: molecule))
                    case "HETATM":
                        hetatoms.append(self.parseAtom(pdb_entry: pdb_entry, molecule: molecule))
                    default:
                        print("CouldNotParse - " + entry_type)
                }
            }
        }
        
        //all atoms loaded
        var current_base_unit:SCNNode = SCNNode() //THis holds the current AminoAcid or NucleicAcid as dictionary to hold all atoms together
        var currentBase:Int = 0
        var localBase: [ARA_PDBAtom] = []
        
        for atom in atoms
        {
            //print(atom.atom_residue_sequence_id)
            if (atoms.last == atom)
            {
                //bind last acid residue atom array
                localBase.append(atom)
                bind_and_string_beads(localBase:localBase, targetMolecule: molecule, targetScene:targetScene)
                continue
            }
        
            if currentBase != Int(atom.atom_residue_sequence_id)
            {
                if (localBase.count > 0)
                {
                    //bind and string the beads with physicsHinges
                    bind_and_string_beads(localBase: localBase, targetMolecule: molecule, targetScene: targetScene)
                }
                
                //Start new array of Atoms to bind
                currentBase = atom.atom_residue_sequence_id
                localBase = [atom]
                
                continue //goto next atom and keep accumulating until we are ready to change.. watch for LASTATOM which is when we have the last atom in the parser
            }
            
            localBase.append(atom)
            
            
            //-------- Render and Convert ARA_PDBAtom to SCNNode() ---------
            // *** Close this off since we need to add subgroups for proper rigid benzene physics ***
            /*
             var coord_scnVec:SCNVector3
            coord_scnVec = SCNVector3Make(atom.atom_x, atom.atom_y, atom.atom_z)
            
             let sphere = SCNSphere(radius: ARACoreUtils.getAtomSize_vanderwalls(element: atom.element_int) * CGFloat(atomicVertexToARCorrectionFactor) )
             
             sphere.segmentCount = 4;
             sphere.firstMaterial?.diffuse.contents = ARACoreUtils.getAtom_color(element:atom.element_int)
             let sphereNode = SCNNode(geometry: sphere)
             sphereNode.physicsBody = .dynamic()
            sphereNode.name = String(describing: atom_for_id(atom:atom) + "Extra")
             sphereNode.position = SCNVector3(x: coord_scnVec.x * atomicVertexToARCorrectionFactor,
                                              y: coord_scnVec.y * atomicVertexToARCorrectionFactor,
                                              z: coord_scnVec.z * atomicVertexToARCorrectionFactor)
             
             molecule.addChildNode(sphereNode)
             */
            //-------------------------------------------------------------
 
        }
        
        
        molecule.position = targetPosition

        print(molecule.childNodes)
        for child in molecule.childNodes
        {
            print(child.childNodes)
        }
        
        
        ARACoreUtils.centerAtoms(molecule: molecule)

        targetScene.rootNode.addChildNode(molecule)
    }
    
    
    func multiAtomRigidNode(atoms:[ARA_PDBAtom]) -> SCNNode
    {
        let rigidNode = SCNNode()

        let averagePosition:SCNVector3 = averagePos(atoms:atoms)
        
        for atom in atoms
        {
            var coord_scnVec:SCNVector3
            coord_scnVec = SCNVector3Make(atom.atom_x - averagePosition.x, atom.atom_y - averagePosition.y, atom.atom_z - averagePosition.z)
            
            let sphere = SCNSphere(radius: ARACoreUtils.getAtomSize_vanderwalls(element: atom.element_int) * CGFloat(atomicVertexToARCorrectionFactor) )
            
            sphere.segmentCount = 4;
            sphere.firstMaterial?.diffuse.contents = ARACoreUtils.getAtom_color(element:atom.element_int)
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.name = String(describing: atom_for_id(atom:atom) )
            sphereNode.position = SCNVector3(x: coord_scnVec.x * atomicVertexToARCorrectionFactor,
                                             y: coord_scnVec.y * atomicVertexToARCorrectionFactor,
                                             z: coord_scnVec.z * atomicVertexToARCorrectionFactor)
            print("created aid: " + atom_for_id(atom: atom))
            rigidNode.addChildNode(sphereNode)
        }
        
        rigidNode.position = averagePosition
        rigidNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                              shape: SCNPhysicsShape(node: rigidNode,
                                                                     options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        
        return rigidNode
    }
    
    
    func atom_for_id(atom:ARA_PDBAtom) -> String
    {
        return atom.atom_chain_id + "/" + String(atom.atom_residue_sequence_id) + "/" + atom.atom_name
    }
    
    
    func averagePos(atoms:[ARA_PDBAtom]) -> SCNVector3
    {
        var averagePosition = SCNVector3Zero
        
        //compute average
        for atom in atoms
        {
            averagePosition = SCNVector3Make(averagePosition.x + atom.atom_x,
                                             averagePosition.y + atom.atom_y,
                                             averagePosition.z + atom.atom_z)
        }
        
        #if os(OSX)
            averagePosition = SCNVector3Make(averagePosition.x/CGFloat(atoms.count),
                                             averagePosition.y/CGFloat(atoms.count),
                                             averagePosition.z/CGFloat(atoms.count))
        #elseif os(iOS)
            averagePosition = SCNVector3Make(averagePosition.x/Float(atoms.count),
                                             averagePosition.y/Float(atoms.count),
                                             averagePosition.z/Float(atoms.count))
        #endif
        
        return averagePosition
    }
    
    func singleBondToRigid(a:ARA_PDBAtom, b:ARA_PDBAtom, rigid:SCNNode, dist:Float, molecule:SCNNode) -> SCNPhysicsBallSocketJoint
    {
        //Creates only atom A if needed... assumes rigid is created
        
        
        //do we really need the rigid node if the binding to the subNode is going to work??!?!
        // 1. test that single bond to the subNode is going to work...
        // 2. else add the physics bond to the rigidNode at the position of the subNode
        //return singleBond(a: a, b: b, dist: dist, molecule: molecule)
        //Creates the Geometry and physics body if necessary.. otherwise only binds the physics joints
        var sphereNode_a = molecule.childNode(withName: atom_for_id(atom: a), recursively: true)
        
        //print(sphereNode_a)
        
        if (sphereNode_a == nil)
        {
            var coord_scnVec_a:SCNVector3
            coord_scnVec_a = SCNVector3Make(a.atom_x, a.atom_y, a.atom_z)
            
            let sphere_a = SCNSphere(radius: ARACoreUtils.getAtomSize_vanderwalls(element: a.element_int) * CGFloat(atomicVertexToARCorrectionFactor) )
            
            sphere_a.segmentCount = 4;
            sphere_a.firstMaterial?.diffuse.contents = ARACoreUtils.getAtom_color(element:a.element_int)
            sphereNode_a = SCNNode(geometry: sphere_a)
            sphereNode_a?.physicsBody = .dynamic()
            sphereNode_a?.name = String(describing: atom_for_id(atom:a))
            sphereNode_a?.position = SCNVector3(x: coord_scnVec_a.x * atomicVertexToARCorrectionFactor,
                                                y: coord_scnVec_a.y * atomicVertexToARCorrectionFactor,
                                                z: coord_scnVec_a.z * atomicVertexToARCorrectionFactor)
            print("created aid: " + atom_for_id(atom: a))
            molecule.addChildNode(sphereNode_a!)
        }
        
        let sphereNode_b = molecule.childNode(withName: atom_for_id(atom: b), recursively: true)
        let deltaToA = SCNVector3Make((sphereNode_b?.position.x)! - (sphereNode_a?.position.x)!,
                                      (sphereNode_b?.position.y)! - (sphereNode_a?.position.y)!,
                                      (sphereNode_b?.position.z)! - (sphereNode_a?.position.z)!)
        let mag = sqrt(deltaToA.x * deltaToA.x + deltaToA.y * deltaToA.y + deltaToA.z * deltaToA.z)
        let deltaToA_unit = SCNVector3Make(deltaToA.x/mag, deltaToA.y/mag, deltaToA.z/mag)
        
        //CRITICAL TEST POINT... what is the correct place to put the physics joint.... atom_a to atom_b.. b is on the edge at (x,0,0)
        return SCNPhysicsBallSocketJoint(bodyA: sphereNode_a!.physicsBody!,
                                         anchorA: SCNVector3Make(-dist * atomicVertexToARCorrectionFactor, 0, 0),
                                         bodyB: rigid.physicsBody!,
                                         anchorB: SCNVector3Make(-(sphereNode_b?.position.x)! + deltaToA_unit.x*dist*atomicVertexToARCorrectionFactor,
                                                                 -(sphereNode_b?.position.y)! + deltaToA_unit.y*dist*atomicVertexToARCorrectionFactor,
                                                                 -(sphereNode_b?.position.z)! + deltaToA_unit.z*dist*atomicVertexToARCorrectionFactor))
                                         //anchorB: SCNVector3Make(dist * atomicVertexToARCorrectionFactor, 0, 0))

    }
    
    func singleBond(a:ARA_PDBAtom, b:ARA_PDBAtom, dist:Float, molecule:SCNNode) -> SCNPhysicsBallSocketJoint
    {
        //Creates the Geometry and physics body if necessary.. otherwise only binds the physics joints
        var sphereNode_a = molecule.childNode(withName: atom_for_id(atom: a), recursively: true)
        if (sphereNode_a == nil)
        {
            var coord_scnVec_a:SCNVector3
            coord_scnVec_a = SCNVector3Make(a.atom_x, a.atom_y, a.atom_z)
            
            let sphere_a = SCNSphere(radius: ARACoreUtils.getAtomSize_vanderwalls(element: a.element_int) * CGFloat(atomicVertexToARCorrectionFactor) )
            
            sphere_a.segmentCount = 4;
            sphere_a.firstMaterial?.diffuse.contents = ARACoreUtils.getAtom_color(element:a.element_int)
            sphereNode_a = SCNNode(geometry: sphere_a)
            sphereNode_a?.physicsBody = .dynamic()
            sphereNode_a?.name = String(describing: atom_for_id(atom:a))
            sphereNode_a?.position = SCNVector3(x: coord_scnVec_a.x * atomicVertexToARCorrectionFactor,
                                                y: coord_scnVec_a.y * atomicVertexToARCorrectionFactor,
                                                z: coord_scnVec_a.z * atomicVertexToARCorrectionFactor)
            print("created aid: " + atom_for_id(atom: a))
            molecule.addChildNode(sphereNode_a!)
        }
        
        var sphereNode_b = molecule.childNode(withName: atom_for_id(atom: b), recursively: true)
        if (sphereNode_b == nil)
        {
            var coord_scnVec_b:SCNVector3
            coord_scnVec_b = SCNVector3Make(b.atom_x, b.atom_y, b.atom_z)
            
            let sphere_b = SCNSphere(radius: ARACoreUtils.getAtomSize_vanderwalls(element: b.element_int) * CGFloat(atomicVertexToARCorrectionFactor) )
            
            sphere_b.segmentCount = 4;
            sphere_b.firstMaterial?.diffuse.contents = ARACoreUtils.getAtom_color(element:b.element_int)
            sphereNode_b = SCNNode(geometry: sphere_b)
            sphereNode_b?.physicsBody = .dynamic()
            sphereNode_b?.name = String(describing: atom_for_id(atom:b))
            sphereNode_b?.position = SCNVector3(x: coord_scnVec_b.x * atomicVertexToARCorrectionFactor,
                                                y: coord_scnVec_b.y * atomicVertexToARCorrectionFactor,
                                                z: coord_scnVec_b.z * atomicVertexToARCorrectionFactor)
            print("created aid: " + atom_for_id(atom: b))
            molecule.addChildNode(sphereNode_b!)
        }
        
        return SCNPhysicsBallSocketJoint(bodyA: sphereNode_a!.physicsBody!,
                                         anchorA: SCNVector3Make(-dist * atomicVertexToARCorrectionFactor, 0, 0),
                                         bodyB: sphereNode_b!.physicsBody!,
                                         anchorB: SCNVector3Make(dist * atomicVertexToARCorrectionFactor, 0, 0))
        
    }
    
    
    func containsRibose(atom:[String:ARA_PDBAtom]) -> Bool
    {
        return atom["C5'"] != nil && atom["C4'"] != nil && atom["C3'"] != nil && atom["C2'"] != nil && atom["C1'"] != nil && atom["O5'"] != nil && atom["O4'"] != nil && atom["O3'"] != nil && atom["O2'"] != nil /*Phosphate Optional? && atom["P"] != nil*/
    }
    
    
    func containsGuanine(atom:[String:ARA_PDBAtom]) -> Bool
    {
        return atom["N9"] != nil && atom["N7"] != nil && atom["N3"] != nil && atom["N2"] != nil && atom["N1"] != nil && atom["C8"] != nil && atom["C6"] != nil && atom["C5"] != nil && atom["C4"] != nil && atom["C2"] != nil
    }
    
    
    func bind_and_string_beads(localBase:[ARA_PDBAtom], targetMolecule:SCNNode, targetScene:SCNScene)
    {
        //Build A, T, C, G, U, DA, DT, DC, DG, DU, and I
        switch localBase[0].atom_residue_name {
            case "A":
                print("A " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "T":
                print("T " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "C":
                print("C " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "G":
                print("G " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
                
                //------------------------------
                //    GUANINE
                //------------------------------
                //Build Atom Dictionary
                var atom:[String:ARA_PDBAtom] = [:]
                for local_atom in localBase
                {
                    print(local_atom.atom_char)
                    atom[local_atom.atom_char] = local_atom
                }
                if (containsRibose(atom: atom) &&
                    containsGuanine(atom: atom))
                {
                    targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.5, molecule:targetMolecule))
                    
                    let riboseSugar_rigidNode = multiAtomRigidNode(atoms:[atom["C4'"]!, atom["C3'"]!, atom["C2'"]!, atom["C1'"]!, atom["O4'"]!])
                    targetMolecule.addChildNode(riboseSugar_rigidNode)
                    
                    targetScene.physicsWorld.addBehavior(singleBondToRigid(a:atom["C5'"]!, b:atom["C4'"]!, rigid:riboseSugar_rigidNode, dist: 0.5, molecule:targetMolecule))
                    
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    //targetScene.physicsWorld.addBehavior(singleBond(a:atom["O5'"]!, b:atom["C5'"]!, dist: 0.15, molecule:targetMolecule))
                    
                    //print(targetMolecule.childNodes)
                    //for child in targetMolecule.childNodes
                    //{
                    //    print(child.childNodes)
                    //}
                }
            
            
            
            
            
                // 11 bonds of nucleic acid G
            
            case "U":
                print("U " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "DA":
                print("DA " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "DT":
                print("DT " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "DC":
                print("DC " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "DG":
                print("DG " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "DU":
                print("DU " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            case "I":
                print("I " + String(localBase.count) + " chain: " + localBase[0].atom_chain_id)
            default:
                print("*** UNKNOWN BASE!!! ***")
        }
    }
    
    
    func parseAtom(pdb_entry:String, molecule:SCNNode) -> ARA_PDBAtom
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
        
        //PDB Alanine Entry Example
        //ATOM      1  N   ALA A   4      11.746  37.328  28.300  1.00 35.74           N
        //PDB Adenine Entry Example
        //ATOM    125  P     A A   7      31.379   1.230   6.849  1.00 29.78           P

        let element_int:Int = ARACoreUtils.periodic_table_element_for_string(element: atom_element)
        
        let atom:ARA_PDBAtom = ARA_PDBAtom()
        
        atom.atom_id = atom_id
        atom.atom_name = atom_name
        atom.atom_char = atom_char
        atom.atom_residue_name = atom_residue_name
        atom.atom_chain_id = atom_chain_id
        atom.atom_residue_sequence_id = Int(atom_residue_sequence_id)
        atom.atom_iCode = atom_iCode
        
        #if os(OSX)
            atom.atom_x = CGFloat(Float(atom_x)!)
            atom.atom_y = CGFloat(Float(atom_y)!)
            atom.atom_z = CGFloat(Float(atom_z)!)
        #elseif os(iOS)
            atom.atom_x = Float(atom_x)!
            atom.atom_y = Float(atom_y)!
            atom.atom_z = Float(atom_z)!
        #endif
        
        atom.atom_occupancy = atom_occupancy
        atom.atom_tempFactor = atom_tempFactor
        atom.atom_element = atom_element
        atom.atom_charge = atom_charge
        atom.element_int = element_int
        
        
        //-------- Render and Convert ARA_PDBAtom to SCNNode() ---------
        //*** Close this off since we need to add subgroups for proper rigid benzene physics ***
        /*
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
        sphereNode.name = atom_for_id(atom:atom)
        sphereNode.position = SCNVector3(x: coord_scnVec.x * atomicVertexToARCorrectionFactor,
                                         y: coord_scnVec.y * atomicVertexToARCorrectionFactor,
                                         z: coord_scnVec.z * atomicVertexToARCorrectionFactor)
        
        molecule.addChildNode(sphereNode)
         */
        //--------------------------------------------------------------
        
        return atom
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
