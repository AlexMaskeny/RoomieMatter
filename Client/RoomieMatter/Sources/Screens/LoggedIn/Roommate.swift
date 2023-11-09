

import SwiftUI

struct Roommate: Identifiable{
    var id: String
    var displayName: String
    var photoURL: String?
    var status: Status
    
    static var Example1 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs2", displayName: "David Wang", status: .studying)
    static var Example2 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs1", displayName: "Alexander David Maskeny", photoURL: "https://lh3.googleusercontent.com/a/ACg8ocJt1Aq-Ispdj61KV4np-4ECP6TrTxYdrP2BXIrPWaXXzQw=s96-c", status: .home)
    static var Example3 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs3", displayName: "Teresa Lee", status: .sleeping)
    static var Example4 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs4", displayName: "Dylan Shelton", status: .inClass)
    
    var image: AsyncImage<_ConditionalContent<Image, Image>>?{
        if let photoURL = photoURL{
            return AsyncImage(url: URL(string: photoURL)) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "person.fill")
            }
        }
        return nil
    }
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
