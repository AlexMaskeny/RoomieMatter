

import Foundation

struct Chore: Identifiable{
    let id: String
    var name: String
    var date: Double
    var description: String
    var author: Roommate
    var assignedRoommates: [Roommate]
    var frequency: Frequency
    
    static let Example1 = Chore(id: "1", name: "Clean Living Room", date: Date().timeIntervalSince1970, description: "Vacuum and mop living room.", author: Roommate.Example2, assignedRoommates: [Roommate.Example1], frequency: .once)
    static let Example2 = Chore(id: "2", name: "Prepare Thanksgiving Dinner", date: Date().timeIntervalSince1970 + 86400, description: "This Thursday we will have a small dinner with some friends. Could you make it?", author: Roommate.Example2, assignedRoommates: [Roommate.Example3, Roommate.Example2, Roommate.Example4], frequency: .weekly)
    
    enum Frequency{
        case once
        case daily
        case weekly
        case monthly
        case biweekly
    }
}
