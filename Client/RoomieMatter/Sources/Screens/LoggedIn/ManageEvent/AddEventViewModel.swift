//
//  AddEventViewModel.swift
//  RoomieMatter
//
//  Created by Lasya Mantha on 11/29/23.
//

import Foundation
import FirebaseFunctions
import GoogleSignIn

class AddEventViewModel:ObservableObject{
    @Published var name = ""
    @Published var date = Date.now
    @Published var dateEnd = Date.now
    @Published var description = ""
    @Published var author: Roommate
    @Published var guests = [Roommate]()
    @Published var addGuests = false
    var possibleGuests: [Roommate] {
        var ret = [author]
        ret.append(contentsOf: roommates)
        return ret
    }
    var roommates: [Roommate]
    
    func saveEvent(){
        guard !name.isEmpty else { return }
        guard !description.isEmpty else { return }
        guard date <= dateEnd else { return }
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        
        let token = user.accessToken.tokenString
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let data: [String: Any] = ["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? "", "eventName": name, "startDatetime": formatter.string(from: date),
                                   "endDatetime": formatter.string(from: dateEnd), "description": "description", "guests": guests.map({ guest in
            guest.id
        })]
        
        Functions.functions().httpsCallable("addEvent").call(data) { (result, error) in
            print("in addEvent")
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Error: \(message)")
                }
                // Handle the error
            }
            if let data = result?.data as? [String: Any] {
                print(data)
            }
        }
    }
    
    init(author: Roommate, roommates: [Roommate]){
        self.roommates = roommates
        self.author = author
    }
    
    func checkContains(roommate: Roommate) -> Bool{
        guests.contains { roommate1 in
            roommate1.id == roommate.id
        }
    }
}


