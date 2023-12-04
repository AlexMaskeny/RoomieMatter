import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import GoogleSignIn
import Foundation

@MainActor
class LoggedInViewViewModel: ObservableObject{
    @Published var user: Roommate
    @Published var chores: [Chore]
    var myChores: [Chore]{
        chores.filter { chore in
            chore.checkContains(roommate: user)
        }
    }
    @Published var events: [Event]
    var myEvents: [Event] {
        events.filter { event in
            event.checkContains(roommate: user)
        }
    }
    @Published var roommates: [Roommate]
    @Published var roomName = ""
    var listener: ListenerRegistration?
    
    init(){
        chores = [Chore]()
        events = [Event]()
        roommates = [Roommate]()
        
        if Auth.auth().currentUser == nil {
            user = Roommate(id: "1", displayName: "Demo User", status: .home)
            self.getChores()
            self.getEvents()
            self.roommates = [Roommate.Example1, Roommate.Example2, Roommate.Example3, Roommate.Example4]
        } else {
            let userID = Auth.auth().currentUser?.uid ?? "uid"
            let displayName = Auth.auth().currentUser?.displayName ?? "unknown"
            let photoURL = Auth.auth().currentUser?.photoURL
            self.user = Roommate(id: userID, displayName: displayName, photoURL: photoURL, status: .home)
            let userRef = db.collection("users").document(userID)
            db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in
                guard let snapshot = snapshot else { return }
                guard snapshot.documents.count > 0 else { print("documents cound = 0"); return }
                guard let roomRef = snapshot.documents[0].get("room") as? DocumentReference else { return }
                
                
                roomRef.getDocument { snapshot1, error in
                    if let roomName = snapshot1?.get("name") as? String {
                        self.roomName = roomName
                    }
                }
                
                
                self.listener = db.collection("user_rooms").whereField("room", isEqualTo: roomRef).whereField("user", isEqualTo: userRef).addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    guard documents.count == 1 else { return }
                    guard let userStatus = documents[0].data()["status"] as? String else { return }
                    self.user.status = interpretString(status: userStatus)
                }
            }
            getChores1()
            getEvents1()
            getRoommates1()
        }
        
        
        
        
        
        
        
        
        
    }
    
    func getRoommates1(){
        if Auth.auth().currentUser != nil{
            let userRef = db.collection("users").document(user.id)
            db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in
                guard let snapshot = snapshot else { print("Error getting snapshot"); return }
                guard snapshot.documents.count > 0 else { print("Snapshot count = 0"); return }
                
                let roomRef = snapshot.documents[0].get("room") as! DocumentReference
                
                db.collection("user_rooms").whereField("room", isEqualTo: roomRef).getDocuments { snapshot1, error in
                    if let snapshot1 = snapshot1 {
                        for document in snapshot1.documents{
                            if userRef == document.data()["user"] as! NSObject{
                                guard let userStatus = document.data()["status"] as? String else {return}
                                self.user.status = interpretString(status: userStatus)
                            } else{
                                guard let roommateStatus = document.data()["status"] as? String else {return}
                                let roommateRef = document.data()["user"] as! DocumentReference
                                roommateRef.getDocument { snapshot2, error in
                                    if let snapshot2 = snapshot2{
                                        guard let roommateDisplayName = snapshot2.get("displayName") as? String else {return}
                                        guard let roommatePhotoURL = snapshot2.get("photoUrl") as? String else {return}
                                        guard let roommateID = snapshot2.get("uuid") as? String else {return}
                                        self.roommates.append(Roommate(id: roommateID, displayName: roommateDisplayName, photoURL: URL(string: roommatePhotoURL), status: interpretString(status: roommateStatus)))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            roommates = [Roommate.Example1, Roommate.Example2, Roommate.Example3, Roommate.Example4]
        }
        
    }
    
    func getChores(){
        chores = [Chore.Example1, Chore.Example2]
    }
    
    func getChores1(){
        chores.removeAll()
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        let token = user.accessToken.tokenString
        
        print("DEBUG roomID \(AuthenticationViewModel.shared.room_id)")
        
        Functions.functions().httpsCallable("getChores").call(["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? ""]) { (result, error) in
            
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Error: \(message)")
                }
            }
            guard let result = result else { print("Error unwrapping result"); return }
            //print(result.data)
            
            guard let data = result.data as? [String: Any] else { print("Error unwrapping data"); return }
            //print(data)
            //print(data["chores"])
            //print(type(of: data["chores"]))
            guard let chores = data["chores"] as? [Any] else { print("Error unwrapping data1"); return }
            for choreDict in chores {
                guard let chore = choreDict as? [String:Any] else { print("Error unwrapping data2"); return }
                //print(chore)
                var id = chore["instanceId"] as? String ?? UUID().uuidString
                var name = chore["eventName"] as? String ?? " "
                var date = chore["date"] as? String ?? " "
                var freq = chore["frequency"] as? String ?? " "
                var description = chore["description"] as? String ?? " "
                var authorID = chore["author"] as? String ?? "uqWhv6HG6QPqjGyJV2a9FF6R1pm2" //CHANGE
                
                var assignedRoommateIDs = chore["assignedRoommates"] as? [String] ?? [] //CHange
                var assignedRoommates = [Roommate]()
                for assignedRoommateID in assignedRoommateIDs {
                    assignedRoommates.append(self.findRoommate(id: assignedRoommateID))
                }
                
                let newChore = Chore(id: id, name: name, date: self.getDate(date: date).timeIntervalSince1970, description: description, author: self.findRoommate(id: authorID), assignedRoommates: assignedRoommates, frequency: interpretFrequency(frequency: freq))
                
                self.chores.append(newChore)
            }
            
        }
        chores.sort { lhs, rhs in
            lhs.date < rhs.date
        }
    }
    
    func getEvents(){
        events = [Event.Example1, Event.Example2]
    }
    
    func getEvents1(){
        events.removeAll()
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        let token = user.accessToken.tokenString
        
        Functions.functions().httpsCallable("getEvents").call(["token": token, "roomId": AuthenticationViewModel.shared.room_id ?? ""]) { result, error in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Error: \(message)")
                }
            }
            guard let result = result else { print("Error unwrapping result"); return }
            print(result.data)
            guard let data = result.data as? [String: Any] else { print("Error unwrapping data"); return }
            
            guard let events = data["events"] as? [Any] else { print("Error unwrapping data[events"); return }
            
            for eventDict in events{
                guard let event = eventDict as? [String:Any] else { print("Error unwrapping data2"); return }
                
                var author = event["author"] as? String ?? ""
                var description = event["description"] as? String ?? ""
                var endDatetime = event["endDatetime"] as? String ?? ""
                var eventId = event["eventId"] as? String ?? UUID().uuidString
                var eventName = event["eventName"] as? String ?? ""
                var startDatetime = event["startDatetime"] as? String ?? ""
                var guestsID = event["guests"] as? [String] ?? []
                //var guests = [Roommate]()
                var guests = guestsID.map { ID in
                    self.findRoommate(id: ID)
                }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                let newEvent = Event(id: eventId, name: eventName, date: formatter.date(from: startDatetime)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970, dateEnd: formatter.date(from: endDatetime)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970, description: description, author: self.findRoommate(id: author), Guests: guests)
                
                self.events.append(newEvent)
            }
        }
        events.sort { lhs, rhs in
            lhs.date < rhs.date
        }
    }
    
    
    
    func getDate(date:String) -> Date{
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd"
        return formatter.date(from: date) ?? Date()
    }
    
    func findRoommate(id: String) -> Roommate {
        var bigArr = roommates
        bigArr.append(user)
        for roommate in bigArr {
            if roommate.id == id{
                return roommate
            }
        }
        return Roommate.Example1
    }
}
