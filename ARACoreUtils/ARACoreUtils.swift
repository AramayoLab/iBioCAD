//
//  ARACoreUtils.swift
//  ARACoreUtils
//
//  Created by Rudy Aramayo on 2/2/18.
//  Copyright © 2018 OrbitusBiomedical. All rights reserved.
//

import Foundation


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
        let element_noSpaces = element.replacingOccurrences(of:" ", with: "")//remove spaces
        
        let periodic_table:[String:String] = ["NA":"0", "H":"1", "He":"2",
          "Li":"3", "Be":"4", "B":"5", "C":"6", "N":"7", "O":"8", "F":"9", "Ne":"10",
            "Na":"11", "Mg":"12", "Al":"13", "Si":"14", "P":"15", "S":"16", "Cl":"17", "Ar":"18",
            "K":"19", "Ca":"20", "Sc":"21", "Ti":"22", "V":"23", "Cr":"24", "Mn":"25", "Fe":"26", "Co":"27", "Ni":"28", "Cu":"29", "Zn":"30", "Ga":"31", "Ge":"32", "As":"33", "Se":"34", "Br":"35", "Kr":"36",
            "Rb":"37", "Sr":"38", "Y":"39", "Zr":"40", "Nb":"41", "Mo":"42", "Tc":"43", "Ru":"44", "Rh":"45", "Pd":"46", "Ag":"47", "Cd":"48", "In":"49", "Sn":"50", "Sb":"51", "Te":"52", "I":"53", "Xe":"54",
            "Cs":"55", "Ba":"56", "La":"57", "Ce":"58", "Pr":"59", "Nd":"60", "Pm":"61", "Sm":"62", "Eu":"63", "Gd":"64", "Tb":"65", "Dy":"66", "Ho":"67", "Er":"68", "Tm":"69", "Yb":"70", "Lu":"71", "Hf":"72", "Ta":"73", "W":"74", "Re":"75", "Os":"76", "Ir":"77", "Pt":"78", "Au":"79", "Hg":"80", "Tl":"81", "Pb":"82", "Bi":"83", "Po":"84", "At":"85", "Rn":"96",
            "Fr":"87", "Ra":"88", "Ac":"89", "Th":"90", "Pa":"91", "U":"92", "Np":"93", "Pu":"94", "Am":"95", "Cm":"96", "Bk":"97", "Cf":"98", "Es":"99", "Fm":"100", "Md":"101", "No":"102", "Lr":"103", "Rf":"104", "Db":"105", "Sg":"106", "Bh":"107", "Hs":"108", "Mt":"109", "Ds":"110", "Rg":"111", "Cn":"112", "Nh":"113", "Fl":"114", "Mc":"115", "Lv":"116", "Ts":"117", "Og":"118"]
        
        let element_int = Int(periodic_table[element_noSpaces]!)
        return element_int!
    }
    
    public class func getAtomSize_vanderwalls(element: Int) -> CGFloat
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
        
        print(atom_color)
        return(atom_color)
    }
    
}
