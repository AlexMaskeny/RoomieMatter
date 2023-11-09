

import Foundation

struct Chore{
    let name: String
    let date: Double
    let discription: String
    var assignedRoommates: [Roommate]
    
    static let Example1 = Chore(name: "Clean Living Room", date: Date().timeIntervalSince1970, discription: "Vacuum and mop living room.", assignedRoommates: [Roommate.Example1])
    static let Example2 = Chore(name: "Prepare Thanksgiving Dinner", date: Date().timeIntervalSince1970 + 86400, discription: "This Thursday we will have a small dinner with some friends. Could you make it?", assignedRoommates: [Roommate.Example3, Roommate.Example4])
}
