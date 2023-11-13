//
//  Chore.swift
//  RoomieMatter
//
//  Created by Dylan Shelton on 11/7/23.
//

import Foundation

//TODO: change to nullable types
struct Chore{
    let name: String
    let date: Double
    let description: String
    var assignedRoommates: [Roommate]
    
    static let Example1 = Chore(name: "Clean Living Room", date: Date().timeIntervalSince1970, description: "Vacuum and mop living room.", assignedRoommates: [Roommate.Example1])
    static let Example2 = Chore(name: "Prepare Thanksgiving Dinner", date: Date().timeIntervalSince1970 + 86400, description: "This Thursday we will have a small dinner with some friends. Could you make it?", assignedRoommates: [Roommate.Example3, Roommate.Example4])
}

//struct Chore {
//    var name: String?
//    var date: Double?
//    var description: String?
//    var assignedRoomates: [Roommate]?
//}
