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


@Observable final class AuthenticationViewModel {
    var username: String?
    var roomname: String?
    private var db = Firestore.firestore()
    private var user_uid: String?
    
    init() {
        fetchUsername()
        fetchRoomname()
    }

    func fetchUsername() {
        if let currentUser = Auth.auth().currentUser {
            username = currentUser.displayName
            user_uid = currentUser.uid
        } else {
            username = nil
            user_uid = nil
        }
    }
    
    func fetchRoomname() {
        guard let user_uid = user_uid else {
            print("Cannot fetch roomname - failed to fetch signed in user")
            return
        }
        
        let userRef = db.collection("users").document(user_uid)
        
        db.collection("user_rooms").whereField("user", isEqualTo: userRef).getDocuments { userRoomDocSnapshot, error in
            guard error == nil else {
                print("Error getting user: \(error!.localizedDescription)")
                return
            }
            
            let roomRef = userRoomDocSnapshot!.documents[0].get("room") as! DocumentReference
            roomRef.getDocument { (roomSnapshot, error) in
                guard error == nil else {
                    print("Error getting user: \(error!.localizedDescription)")
                    return
                }
                
                if let roomName = roomSnapshot?.get("name") as? String {
                    self.roomname = roomName
                } else {
                    print("Cannot fetch roomname - name field does not exist")
                }
            }
        }
    }

    func refresh() {
        fetchUsername()
        fetchRoomname()
    }

}

