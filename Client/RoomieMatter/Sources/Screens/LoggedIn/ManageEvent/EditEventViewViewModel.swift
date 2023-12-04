

import Foundation
import FirebaseFunctions
import GoogleSignIn

class EditEventViewModel:ObservableObject{
    @Published var event: Event
    var user: Roommate
    @Published var dateStart = Date.now
    @Published var dateEnd = Date.now
    @Published var addAssignees = false
    var possibleAssignees: [Roommate]  {
        var ret = [user]
        ret.append(contentsOf: roommates)
        return ret
    }
    var roommates: [Roommate]
    
    init(roommates: [Roommate], event: Event, user: Roommate){
        self.roommates = roommates
        self.event = event
        dateStart = Date(timeIntervalSince1970: event.date)
        dateEnd = Date(timeIntervalSince1970: event.dateEnd)
        self.user = user
    }
    
    func saveEvent(){
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        let token = user.accessToken.tokenString
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let data: [String: Any] = ["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? "", "eventId": event.id, "eventName": event.name, "startDatetime": formatter.string(from: dateStart), "endDatetime": formatter.string(from: dateEnd), "description": event.description, "guests": event.Guests.map({ guest in
            guest.id
        })]
        
        Functions.functions().httpsCallable("editEvent").call(data) { (result, error) in
                print("in editEvent")
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
    
    func deleteEvent(){
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        
        let token = user.accessToken.tokenString
        
        let data = ["token": token, "eventId": event.id, "roomId": AuthenticationViewModel.shared.room_id ?? ""]
        
        Functions.functions().httpsCallable("deleteEvent").call(data) { (result, error) in
                print("in deleteEvent")
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
}
