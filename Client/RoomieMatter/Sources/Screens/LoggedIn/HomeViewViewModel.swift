import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

class HomeViewViewModel: ObservableObject {
    @Published var roommates: [Roommate]
    var chores: [Chore]
    let user: Roommate
    
    func interpretString(status: String) -> Status{
        switch status{
        case "At home":
            return .home
        case "Studying":
            return .studying
        case "In class":
            return .inClass
        default:
            return .sleeping
        }
    }
    
    func getRoommates(){
        var roomName1 = ""
        let userRef = db.collection("users").document(user.id)
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { snapshot, error in
            
            let roomRef = snapshot!.documents[0].get("room") as! DocumentReference
            
            /*
            db.collection("user_rooms").whereField("room", isEqualTo: roomRef).getDocuments { snapshot1, error1 in
                if let name = snapshot1?.get("status") as? String{
                    print(name)
                }
            }
            */
            
            roomRef.getDocument { roomSnapShot, error1 in
                if let roomName = roomSnapShot?.get("name") as? String{
                    roomName1 = roomName
                    print(roomName1)
                }
            }
            
            db.collection("user_rooms").whereField("room", isEqualTo: roomRef).getDocuments { snapshot1, error in
                if let snapshot1 = snapshot1 {
                    for document in snapshot1.documents{
                        if userRef == document.data()["user"] as! NSObject{
                        } else{
                            guard let roommateStatus = document.data()["status"] as? String else {return}
                            let roommateRef = document.data()["user"] as! DocumentReference
                            roommateRef.getDocument { snapshot2, error in
                                if let snapshot2 = snapshot2{
                                    guard let roommateDisplayName = snapshot2.get("displayName") as? String else {return}
                                    guard let roommatePhotoURL = snapshot2.get("photoUrl") as? String else {return}
                                    guard let roommateID = snapshot2.get("uuid") as? String else {return}
                                    self.roommates.append(Roommate(id: roommateID, displayName: roommateDisplayName, photoURL: URL(string: roommatePhotoURL), status: self.interpretString(status: roommateStatus)))
                                }
                            }
                        }
                    }
                }
            }
            
            
        }
    }
    
    init(){
        let userID = Auth.auth().currentUser?.uid ?? "uid"
        let displayName = Auth.auth().currentUser?.displayName ?? "unkniown"
        let photoURL = Auth.auth().currentUser?.photoURL
        user = Roommate(id: userID, displayName: displayName, photoURL: photoURL, status: .home)
        
        roommates = [Roommate]()
        chores = [Chore.Example1, Chore.Example2]
        getRoommates()
    }
}
