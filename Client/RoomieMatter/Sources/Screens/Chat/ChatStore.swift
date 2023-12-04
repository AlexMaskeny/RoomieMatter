//
//  ChatStore.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI
import FirebaseFunctions
import Observation
import GoogleSignIn

@Observable
final class ChatStore: ObservableObject {
    static let shared = ChatStore()
    let authViewModel = AuthenticationViewModel.shared
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private(set) var chats: [Chat] = []
    var idSet = Set<String>()
    
    init() {
        listenForChats()
        authViewModel.refresh()
    }
    
    func sendChat(msg: String) {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        let token = user.accessToken.tokenString
        
        let params = [
            "token": token,
            "userId": authViewModel.user_uid,
            "roomId": authViewModel.room_id,
            "content": msg
        ]
        Functions.functions().httpsCallable("sendChat").call(params) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Error: \(String(describing: code)) \(message) \(String(describing: details))")
                }
            }
            if let data = result?.data as? [String: Any] {
                print(data)
            }
        }
    }
    
    func getChats(triesRemaining: Int = 5, onAppear: Bool = false, onNew: Bool = false, scroll: (() -> Void)? = nil) {
        print("getChats running")
 
        let params = [
            "roomId": authViewModel.room_id,
            "maxTimestamp": !self.chats.isEmpty && (onAppear || onNew) ? "" : self.chats.isEmpty ? ChatStore.dateFormatter.string(from: Date.now) : ChatStore.dateFormatter.string(from: self.chats.first!.timestamp),
            "minTimestamp": self.chats.isEmpty ? "" :ChatStore.dateFormatter.string(from: self.chats.last!.timestamp)
        ]
        Functions.functions().httpsCallable("getChats").call(params) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Error: \(String(describing: code)) \(message) \(String(describing: details))")
                }
            }

            if let data = result?.data as? [String: Any] {
                
                if let olderHistoryArray = data["olderHistory"] as? [[String: Any]],
                   let newerHistoryArray = data["newerHistory"] as? [[String: Any]] {
                    
                    func parseChatDictionary(_ chatDict: [String: Any]) -> Chat? {
                        guard let role = chatDict["role"] as? String,
                              let message = chatDict["content"] as? String,
                              let isoString = chatDict["createdAt"] as? String,
                              let timestamp = ChatStore.dateFormatter.date(from: isoString),
                              let id = chatDict["id"] as? String else {
                            return nil
                        }
                        
                        if role == "assistant" {
                            return Chat(
                                id: id,
                                username: "HouseKeeper",
                                message: message,
                                timestamp: timestamp
                            )
                        } else if let username = chatDict["displayName"] as? String {
                            return Chat(
                                id: id,
                                username: username,
                                message: message,
                                timestamp: timestamp
                            )
                        }
                        
                        return nil
                    }
                    
                    var fetchedChats: [Chat] = []
                    
                    for chatDict in olderHistoryArray {
                        if let chat = parseChatDictionary(chatDict) {
                            if !self.idSet.contains(chat.id) {
                                fetchedChats.append(chat)
                                self.idSet.insert(chat.id)
                            }
                        }
                    }
                    
                    fetchedChats += self.chats
                    
                    for chatDict in newerHistoryArray {
                        if let chat = parseChatDictionary(chatDict) {
                            if !self.idSet.contains(chat.id) {
                                fetchedChats.append(chat)
                                self.idSet.insert(chat.id)
                            }
                        }
                    }
                    
                    self.chats = fetchedChats
                    print("done getting chats")
                    if !newerHistoryArray.isEmpty || !olderHistoryArray.isEmpty {
                        scroll?()
                    }
                }
            } else {
                if triesRemaining > 0 {
                    print("Retrying getting chats")
                    sleep(1)
                    self.getChats(triesRemaining: triesRemaining - 1)
                } else {
                    print("Error getting chats")
                }
            }
        }
    }
    
    private func listenForChats() {
        db.collection("chats")
          .addSnapshotListener { querySnapshot, error in
              guard let documents = querySnapshot?.documents else {
                  print("Error fetching documents: \(error!)")
                  return
              }
              
              ChatStore.shared.getChats(onNew: true)
          }
    }
}
