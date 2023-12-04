

import SwiftUI

struct Roommate: Identifiable{
    var id: String
    var displayName: String
    var photoURL: URL?
    var status: Status
    static var Example1 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs2", displayName: "David Wang", status: .studying)
    static var Example2 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs1", displayName: "Alexander David Maskeny", photoURL: URL(string: "https://lh3.googleusercontent.com/a/ACg8ocJt1Aq-Ispdj61KV4np-4ECP6TrTxYdrP2BXIrPWaXXzQw=s96-c"), status: .home)
    static var Example3 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs3", displayName: "Teresa Lee", status: .sleeping)
    static var Example4 = Roommate(id: "ALfAiMtHmWhfUgaSQWGIUHUujUs4", displayName: "Dylan Shelton", status: .notHome)
    
    var image: AsyncImage<_ConditionalContent<Image, Image>>?{
        if let photoURL = photoURL{
            return AsyncImage(url: photoURL) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "person.fill")
            }
        }
        return nil
    }
}
