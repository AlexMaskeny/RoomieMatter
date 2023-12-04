

import Foundation
import FirebaseFunctions
import GoogleSignIn

class EditChoreViewModel:ObservableObject{
    @Published var chore: Chore
    @Published var date: Date
    @Published var addAssignees = false
    var roommates: [Roommate]
    
    init(roommates: [Roommate], chore: Chore){
        self.roommates = roommates
        self.chore = chore
        self.date = Date(timeIntervalSince1970: chore.date)
    }
    
    func saveChore(){
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        let token = user.accessToken.tokenString
        
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd"
        let dateStr = formatter.string(from: Date.init(timeIntervalSince1970: chore.date))
        
        let data: [String: Any] = ["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? "", "instanceId": chore.id, "eventName": chore.name, "date": dateStr, "frequency": chore.frequency.asString,
                                   "endRecurrenceDate": "2023-12-30", "description": chore.description, "assignedRoommates": chore.assignedRoommates.map({ roommate in roommate.id })]
        
        Functions.functions().httpsCallable("editChore").call(data) { result, error in
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
    
    func deleteChore(){
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        
        let token = user.accessToken.tokenString
        
        let data = ["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? ""]
        
        Functions.functions().httpsCallable("deleteChore").call(data) { result, error in
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
