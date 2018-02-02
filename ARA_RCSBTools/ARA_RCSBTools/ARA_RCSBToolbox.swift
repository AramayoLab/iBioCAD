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
    
    
}
