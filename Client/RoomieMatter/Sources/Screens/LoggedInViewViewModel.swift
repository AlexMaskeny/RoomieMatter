import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

class LoggedInViewViewModel: ObservableObject{
    @Published var user: Roommate
    @Published var roomName = ""
    
    init(){
        let userID = Auth.auth().currentUser?.uid ?? "uid"
        let displayName = Auth.auth().currentUser?.displayName ?? "unkniown"
        let photoURL = Auth.auth().currentUser?.photoURL
        
        self.user = Roommate(id: userID, displayName: displayName, photoURL: photoURL, status: .home)
        
        let userRef = db.collection("users").document(user.id)
        
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in
            
            let roomRef = snapshot!.documents[0].get("room") as! DocumentReference
            
            roomRef.getDocument { snapshot1, error in
                if let roomName = snapshot1?.get("name") as? String {
                    self.roomName = roomName
                }
            }
            
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
