//
//  AddModelTip.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 4.1.25.
//

import TipKit

struct AddModelTip: Tip {
    
    var title: Text {
        Text("Place your first furniture")
    }
    
    var message: Text? {
        Text("Tap on the location where you'd like to place the model")
    }
    
    static let addRoomControllerVisitedEvent = Event(id: "AddRoomControllerVisited")
    
    var rules: [Rule] {
        #Rule(Self.addRoomControllerVisitedEvent) { event in
            event.donations.count == 0
        }
    }
}
