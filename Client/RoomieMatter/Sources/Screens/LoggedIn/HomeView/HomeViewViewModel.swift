import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

class HomeViewViewModel: ObservableObject {
    @Published var roommates: [Roommate]
    var chores: [Chore]
    
    var myChores: [Chore]{
        chores.filter { chore in
            chore.checkContains(roommate: user)
        }
    }
    
    var events: [Event]
    
    var myEvents: [Event] {
        events.filter { event in
            event.checkContains(roommate: user)
        }
    }
    @Published var user: Roommate
    
    
    
    func getRoommates(){
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
    
    init(chores: [Chore], events: [Event]){
        let userID = Auth.auth().currentUser?.uid ?? "uid"
        let displayName = Auth.auth().currentUser?.displayName ?? "unkniown"
        let photoURL = Auth.auth().currentUser?.photoURL
        user = Roommate(id: userID, displayName: displayName, photoURL: photoURL, status: .home)
        
        roommates = [Roommate]()
        self.chores = chores
        self.events = events
        getRoommates()
    }
}
