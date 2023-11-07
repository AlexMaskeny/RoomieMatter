

import SwiftUI

struct Roommate{
    let name: String
    var status: Status
    
    static var Example1 = Roommate(name: "David Wang", status: .studying)
    static var Example2 = Roommate(name: "Alex Maskeny", status: .home)
    static var Example3 = Roommate(name: "Teresa Lee", status: .sleeping)
    static var Example4 = Roommate(name: "Dylan Shelton", status: .inClass)
}

enum Status{
    case studying
    case home
    case sleeping
    case inClass
    
    var color: Color{
        switch self {
        case .studying:
            Color.red
        case .home:
            Color.green
        case .sleeping:
            Color.gray
        case .inClass:
            Color.red
        }
    }
    
    var status: String{
        switch self {
        case .studying:
            "Studying"
        case .home:
            "At Home"
        case .sleeping:
            "Sleeping"
        case .inClass:
            "In Class"
        }
    }
}
