//
//  AuthenticationViewModel.swift
//  RoomieMatter
//
//  Created by David Wang on 11/5/23.
//

import SwiftUI
import Observation
import Firebase
import FirebaseAuth
import FirebaseFirestore


@Observable
final class AuthenticationViewModel {
    var username: String?
    var user_uid: String?
    var roomname: String?
    var room_id: String?
    private var db = Firestore.firestore()
    static let shared = AuthenticationViewModel()
    
    init() {
        fetchUser()
        fetchRoom()
    }

    func fetchUser(completion: (() -> Void)? = nil) {
        if let currentUser = Auth.auth().currentUser {
            username = currentUser.displayName
            user_uid = currentUser.uid
        } else {
            username = nil
            user_uid = nil
        }
        completion?()
    }
    
    func fetchRoom(completion: (() -> Void)? = nil) {
        guard let user_uid = user_uid else {
            print("Error getting room: failed to fetch signed in user")
            return
        }
        
        let userRef = db.collection("users").document(user_uid)
        
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { userRoomDocSnapshot, error in
            guard error == nil else {
                print("Error getting user: \(error!.localizedDescription)")
                completion?()
                return
            }
            
            guard let userRoomDocSnapshot = userRoomDocSnapshot else {
                print("Error getting room: failed to fetch user")
                completion?()
                return
            }

            guard userRoomDocSnapshot.documents.count > 0 else {
                print("Error getting room: failed to fetch room for user")
                completion?()
                return
            }
            
            let roomRef = userRoomDocSnapshot.documents[0].get("room") as! DocumentReference
            roomRef.getDocument { (roomSnapshot, error) in
                guard error == nil else {
                    print("Error getting user: \(error!.localizedDescription)")
                    completion?()
                    return
                }
                
                if let roomName = roomSnapshot?.get("name") as? String,
                   let room_id = roomSnapshot?.documentID {
                    self.roomname = roomName
                    self.room_id = room_id
                } else {
                    print("Error getting room: name field does not exist")
                }
                completion?()
            }
        }
    }

    func refresh() {
        fetchUser()
        fetchRoom()
    }

}

