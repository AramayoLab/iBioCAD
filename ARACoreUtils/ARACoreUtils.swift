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
