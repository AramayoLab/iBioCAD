//
//  ARAAtom.swift
//  ARA_RCSBTools
//
//  Created by Rudy Aramayo on 2/9/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import Foundation

class ARA_PDBAtom: NSObject {
    public var atom_id:String!
    public var atom_name:String!
    public var atom_char:String!
    public var atom_residue_name:String!
    public var atom_chain_id:String!
    public var atom_residue_sequence_id:Int!
    public var atom_iCode:String!
    
    #if os(OSX)
    public var atom_x:CGFloat!
    public var atom_y:CGFloat!
    public var atom_z:CGFloat!
    #elseif os(iOS)
    public var atom_x:Float!
    public var atom_y:Float!
    public var atom_z:Float!
    #endif
    
    
    public var atom_occupancy:String!
    public var atom_tempFactor:String!
    public var atom_element:String!
    public var atom_charge:String!
    public var element_int:Int!
    
    
}
