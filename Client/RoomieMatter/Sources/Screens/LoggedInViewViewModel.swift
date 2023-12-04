import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Foundation

@MainActor
class LoggedInViewViewModel: ObservableObject{
    @Published var user: Roommate
    @Published var chores: [Chore]
    @Published var events: [Event]
    @Published var roomName = ""
    var listener: ListenerRegistration?
    
    init(){
        let userID = Auth.auth().currentUser?.uid ?? "uid"
        let displayName = Auth.auth().currentUser?.displayName ?? "unknown"
        let photoURL = Auth.auth().currentUser?.photoURL
        
        chores = [Chore]()
        events = [Event]()
        
        self.user = Roommate(id: userID, displayName: displayName, photoURL: photoURL, status: .home)
        
        let userRef = db.collection("users").document(userID)
        
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in

            guard let snapshot = snapshot else {return}

            guard snapshot.documents.count > 0 else {return}
            
            let roomRef = snapshot.documents[0].get("room") as! DocumentReference
            
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
        
        getChores()
        getEvents()
    }
    
    func getChores(){
        chores = [Chore.Example1, Chore.Example2]
    }
    
    func getEvents(){
        events = [Event.Example1, Event.Example2]
    }
    
    func getChores1(){
        print("In chores")
        Functions.functions().httpsCallable("testGetChores").call("hello") { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Error: \(message)")
                }
                // Handle the error
            }
            print("In chores1")
            print(result?.data)
            if let data = result?.data as? [String: Any] {
                print("In chores3")
                print(data)
            }
            print("In chores2")
        }
    }
    
    func testStatus(){
        print("Test status")
        let userRef = db.collection("users").document(user.id)
        
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in
            guard let snapshot = snapshot else { return }
            guard !snapshot.documents.isEmpty else { return }
            let roomRef = snapshot.documents[0].documentID
            print("ROOM Ref? = \(roomRef)")
            db.collection("user_rooms").document(roomRef).updateData(["status": "TEST"]) { error in
                print("ERROR \(error?.localizedDescription ?? " ")")
            }
            
        }
    }
    
    func testStatus1(){
        print("Function form")
        let userRef = db.collection("users").document(user.id)
        
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in

            guard let snapshot = snapshot else {return}

            guard snapshot.documents.count > 0 else {return}
            
            let roomRef = snapshot.documents[0].get("room") as! DocumentReference
            
            db.collection("user_rooms").whereField("room", isEqualTo: roomRef).getDocuments { snapshot1, error in
                if let snapshot1 = snapshot1{
                    for document in snapshot1.documents{
                        if userRef == document.data()["user"] as! NSObject{
                            guard let userStatus = document.data()["status"] as? String else {return}
                            self.user.status = interpretString(status: userStatus)
                            return
                        }
                    }
                }
            }
        }
    }
}
