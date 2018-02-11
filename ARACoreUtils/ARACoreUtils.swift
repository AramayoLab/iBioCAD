//
//  ARACoreUtils.swift
//  ARACoreUtils
//
//  Created by Rudy Aramayo on 2/2/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import Foundation
import SceneKit

#if os(macOS)
    
import Cocoa
    typealias Color = NSColor

#else
    
import UIKit
    typealias Color = UIColor

#endif
    
public class ARACoreUtils: NSObject {
    
   
    public class func periodic_table_element_for_int(element:Int) -> String
    {
        
        let periodic_table:[String] = ["-", "H","He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Po", "At", "Rn", "Fr", "Ra", "Ac", "Th", "Pr", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm", "Md", "No", "Lr", "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn", "Nh", "Fl", "Mc", "Lv", "Ts", "Og"]
        
        return periodic_table[element]
    }
    
    public class func periodic_table_element_for_string(element:String) -> Int
    {
        let element_noSpaces = element.replacingOccurrences(of:" ", with: "").uppercased()//remove spaces
        
        let periodic_table:[String:String] = ["":"0", "H":"1", "HE":"2",
          "LI":"3", "BE":"4", "B":"5", "C":"6", "N":"7", "O":"8", "F":"9", "NE":"10",
            "NA":"11", "MG":"12", "AL":"13", "SI":"14", "P":"15", "S":"16", "CL":"17", "AR":"18",
            "K":"19", "CA":"20", "SC":"21", "TI":"22", "V":"23", "CR":"24", "MN":"25", "FE":"26", "CO":"27", "NI":"28", "CU":"29", "ZN":"30", "GA":"31", "GE":"32", "AS":"33", "SE":"34", "BR":"35", "KR":"36",
            "RB":"37", "SR":"38", "Y":"39", "ZR":"40", "NB":"41", "MO":"42", "TC":"43", "RU":"44", "RH":"45", "PD":"46", "AG":"47", "CD":"48", "IN":"49", "SN":"50", "SB":"51", "TE":"52", "I":"53", "XE":"54",
            "CS":"55", "BA":"56", "LA":"57", "CE":"58", "PR":"59", "ND":"60", "PM":"61", "SM":"62", "EU":"63", "GD":"64", "TB":"65", "DY":"66", "HO":"67", "ER":"68", "TM":"69", "YB":"70", "LU":"71", "HF":"72", "TA":"73", "W":"74", "RE":"75", "OS":"76", "IR":"77", "PT":"78", "AU":"79", "HG":"80", "TL":"81", "PB":"82", "BI":"83", "PO":"84", "AT":"85", "RN":"96",
            "FR":"87", "RA":"88", "AC":"89", "TH":"90", "PA":"91", "U":"92", "NP":"93", "PU":"94", "AM":"95", "CM":"96", "BK":"97", "CF":"98", "ES":"99", "FM":"100", "MD":"101", "NO":"102", "LR":"103", "RF":"104", "DB":"105", "SG":"106", "BH":"107", "HS":"108", "MT":"109", "DS":"110", "RG":"111", "CN":"112", "NH":"113", "FL":"114", "MC":"115", "LV":"116", "TS":"117", "OG":"118"]
        
        let element_int = Int(periodic_table[element_noSpaces]!)
        return element_int!
    }
    
    public class func getAtomSize_vanderwalls(element: Int) -> CGFloat
    {
        //print("element -", element)
        switch(element)
        {
        case 6:
            //print("carbon")
            return 170/200.0//attometers
        case 8:
            //print("oxygen")
            return 152/200.0//attometers
        case 7:
            //print("nitrogen")
            return 155/200.0//attometers
        case 1:
            //print("hydrogen")
            return 120/200.0//attometers
        default:
            return 100.0/200.0//attometers
        }
    }
    
    #if os(macOS)
    public class func getAtom_color(element:Int) -> NSColor
    {
        return getAtom_color_internal(element:element)
    }
    #else
    public class func getAtom_color(element:Int) -> UIColor
    {
        return getAtom_color_internal(element:element)
    }
    #endif
    
    class func getAtom_color_internal(element:Int) -> Color
    {
        var atom_color = Color.white
        
        switch element
        {
        case 1: //Hydrogen
            atom_color = Color(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            break;
        case 8: //Oxygen
            atom_color = Color(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            break;
        case 7: //Nitrogen
            atom_color = Color(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
            break;
        case 6: //Carbon
            atom_color = Color(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            break;
        case 15: //Phosphorus
            atom_color = Color(red: 0.8, green: 0.8, blue: 0.0, alpha: 1.0)
            break;
        case 11: //Sodium
            atom_color = Color(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0)
            break;
        case 12: //Magnesium
            atom_color = Color(red: 0.2, green: 1.0, blue: 0.0, alpha: 1.0)
            break;
        case 19: //Potassium
            atom_color = Color(red: 0.23, green: 0.8, blue: 0.51, alpha: 1.0)
            break;
        case 20: //Calcium
            atom_color = Color(red: 0.2, green: 0.87, blue: 0.0, alpha: 1.0)
            break;
        case 16: //Sulpher
            atom_color = Color(red: 0.83, green: 0.87, blue: 0.0, alpha: 1.0)
            break;
        case 17: //Chloride
            atom_color = Color(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
            break;
        case 26: //Iron
            atom_color = Color(red: 0.64, green: 0.32, blue: 0.0, alpha: 1.0)
            break;
        case 9: //Florine
            atom_color = Color(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
            break;
        default:
            atom_color = Color.darkGray;
            break;
        }
        
        //print(atom_color)
        return(atom_color)
    }
    
    
    class func centerAtoms(molecule:SCNNode)
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
