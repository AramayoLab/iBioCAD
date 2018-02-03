//
//  ARA_RCSBToolbox.swift
//  ARA_RCSBTools
//
//  Created by Rudy Aramayo on 2/2/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import Foundation


public protocol ARA_RCSB_PDBSearchDelegate {
    func didReturnPDB(pdb:NSDictionary)
    func didFailToReturnPubPDB(message:String, details:String)
}


public class ARA_RCSBToolbox: NSObject {

    public var delegate:ARA_RCSB_PDBSearchDelegate!

    
    public func initToolbox(search_delegate:ARA_RCSB_PDBSearchDelegate) {
        self.delegate = search_delegate
    }
    
    
    public class func printme_imdelicate()
    {
        print("SaveBioScript")
    }
    
    
    public func rcsb_pdbSearchByID(searchTerm:String)
    {
        let url = "https://files.rcsb.org/download/" + searchTerm + ".pdb"
        self.getDataFromUrl(urlString: url) { (data, response, error ) in
            
            let x = String.init(data:data!, encoding:.utf8)
            let pdbArray = x!.components(separatedBy: "\n")

            
            for pdb_entry in pdbArray
            {
                //print(pdb_entry)
                if (pdb_entry.starts(with: "<!DOCTYPE HTML PUBLIC"))
                {
                    self.delegate.didFailToReturnPubPDB(message: "PDB Not Found", details: "")
                    return
                }
                if (pdb_entry != "")
                {
                    let entry_type = String(pdb_entry[0...5])
                    
                    //print(pdb_entry_components)
                    switch (entry_type)
                    {
                        case "ATOM  ":
                            self.parseAtom(pdb_entry: pdb_entry)
                        case "HETATM":
                            self.parseAtom(pdb_entry: pdb_entry)
                        default:
                            print("CouldNotParse - " + entry_type)
                        
                    }
                }
            }
            
        }
    }
    
    
    func parseAtom(pdb_entry:String)
    {
        
        //ATOM entry properties
        let atom_id = String(pdb_entry[0...5])
        let atom_name = String(pdb_entry[6...10])
        let atom_char = String(pdb_entry[12...15])
        let atom_residue_name = String(pdb_entry[17...19])
        let atom_chain_id = String(pdb_entry[21...21])
        let atom_residue_sequence_id = String(pdb_entry[22...25])
        let atom_iCode = String(pdb_entry[26...26])
        let atom_x = String(pdb_entry[30...37])
        let atom_y = String(pdb_entry[38...45])
        let atom_z = String(pdb_entry[46...53])
        let atom_occupancy = String(pdb_entry[54...59])
        let atom_tempFactor = String(pdb_entry[60...65])
        let atom_element = String(pdb_entry[76...77])
        let atom_charge = String(pdb_entry[78...79])
        
        //ATOM 52 NH1BARG A -3    14.338 86.056 88.706 0.50 40.23 N
        let color = ARACoreUtils.getAtom_color(element:6); //Carbon = 6
        print(color)
        //let v = ARACoreUtils()
        
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
