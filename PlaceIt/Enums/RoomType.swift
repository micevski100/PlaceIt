//
//  RoomType.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 20.11.24.
//

import Foundation
import UIKit

enum RoomType: String, CaseIterable, CustomStringConvertible {
    
    case livingRoom = "Living Room"
    case diningRoom = "Dining Room"
    case guestRoom = "Guest Room"
    case bedRoom = "Bedroom"
    case bathRoom = "Bathroom"
    case kitchen = "Kitchen"
    case office = "Office"
    
    var image: UIImage {
        switch self {
        case .livingRoom:
            return UIImage(named: "livingroom")!
        case .diningRoom:
            return UIImage(named: "diningroom")!
        case .guestRoom:
            return UIImage(named: "guestroom")!
        case .bedRoom:
            return UIImage(named: "bedroom")!
        case .bathRoom:
            return UIImage(named: "bathroom")!
        case .kitchen:
            return UIImage(named: "kitchen")!
        case .office:
            return UIImage(named: "office")!
        default:
            return UIImage(named: "defaultRoom")!
        }
    }
    
    var description: String {
        return self.rawValue
    }
}
