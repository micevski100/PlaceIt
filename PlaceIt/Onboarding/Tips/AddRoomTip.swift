//
//  AddRoomTip.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 1.1.25.
//

import TipKit

struct AddRoomTip: Tip {
    
    static let addRoomControllerVisitedEvent = Event(id: "AddRoomControllerVisited")
    
    var title: Text {
        Text("Add Room")
    }
    
    var message: Text? {
        Text("Lets start by creating your first virtual room.")
    }
    
    var rules: [Rule] {
        #Rule(Self.addRoomControllerVisitedEvent) { event in
            event.donations.count == 0
        }
    }
}
