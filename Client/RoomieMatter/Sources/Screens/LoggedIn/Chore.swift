

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
    static let Example3 = Chore(id: "3", name: "Prepare Dinner", date: Date().timeIntervalSince1970 - 86400, description: "We will have a small dinner with some friends. Could you make it?", author: Roommate.Example2, assignedRoommates: [Roommate.Example3, Roommate.Example2, Roommate.Example4], frequency: .weekly)
    
    func checkContains(roommate: Roommate) -> Bool{
        assignedRoommates.contains { roommate1 in
            roommate1.id == roommate.id
        }
    }
    
    enum Frequency: CaseIterable{
        case once
        case daily
        case weekly
        case monthly
        case biweekly
        
        var asString: String{
            switch self {
            case .once:
                "Once"
            case .daily:
                "Daily"
            case .weekly:
                "Weekly"
            case .monthly:
                "Monthly"
            case .biweekly:
                "Biweekly"
            }
        }
    }
}

func interpretFrequency(frequency: String) -> Chore.Frequency{
    switch frequency{
    case "Biweekly":
            .biweekly
    case "Daily":
            .daily
    case "Weekly":
            .weekly
    case "Monthly":
            .monthly
    default:
            .once
    }
}
