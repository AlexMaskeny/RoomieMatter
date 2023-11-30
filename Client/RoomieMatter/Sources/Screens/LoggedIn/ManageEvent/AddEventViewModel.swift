//
//  AddEventViewModel.swift
//  RoomieMatter
//
//  Created by Lasya Mantha on 11/29/23.
//

import Foundation

class AddEventViewModel:ObservableObject{
    @Published var newEvent = Chore(id: UUID().uuidString, name: "", date: Date().timeIntervalSince1970, description: "", author: Roommate.Example1, assignedRoommates: [], frequency: .once)
    @Published var date = Date.now
    @Published var showingDatePicker = false
    @Published var addGuests = false
    var roommates: [Roommate]
    
    init(roommates: [Roommate]){
        self.roommates = roommates
    }
}


