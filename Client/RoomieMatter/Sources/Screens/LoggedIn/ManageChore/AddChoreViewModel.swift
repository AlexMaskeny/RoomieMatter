
import Foundation
import FirebaseFunctions
import GoogleSignIn

class AddChoreViewModel:ObservableObject{
    @Published var name = ""
    @Published var date = Date.now
    @Published var description = ""
    @Published var author: Roommate
    @Published var addAssignees = false
    @Published var frequency = Chore.Frequency.once
    @Published var assignedRoommates = [Roommate]()
    var possibleAssignees: [Roommate] {
        var ret = [author]
        ret.append(contentsOf: roommates)
        return ret
    }
    var roommates: [Roommate]
    
    init(author: Roommate, roommates: [Roommate]){
        self.roommates = roommates
        self.author = author
    }
    
    func saveChore(){
        
        guard !name.isEmpty else { return }
        guard !description.isEmpty else { return }
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        let token = user.accessToken.tokenString
        
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd"
        let dateStr = formatter.string(from: date)
        
        let data: [String: Any] = ["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? "","eventName": name, "date": dateStr, "frequency": self.frequency.asString,
                                   "endRecurrenceDate": "2023-12-30", "description": description, "assignedRoommates": assignedRoommates.map({ roommate in roommate.id })]
        Functions.functions().httpsCallable("addChore").call(data) { (result, error) in
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
                //print(data)
            }
        }
        
        
        
    }
    
    func checkContains(roommate: Roommate) -> Bool{
        assignedRoommates.contains { roommate1 in
            roommate1.id == roommate.id
        }
    }
}
