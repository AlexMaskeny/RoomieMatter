//
//  ChatStore.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI
import FirebaseFunctions
import Observation


@Observable
final class ChatStore {
    static let shared = ChatStore()
    private var authViewModel = AuthenticationViewModel()
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private(set) var chats: [Chat] = []
    
    func sendChat(msg: String) {
        let params = [
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
                    print("Error: \(message)")
                }
                // Handle the error
            }
            else {
                self.chats.append(
                    Chat(
                        username: self.authViewModel.username,
                        message: msg,
                        timestamp: Date.now
                    )
                )
            }
            if let data = result?.data as? [String: Any] {
                print(data)
            }
        }
    }
    
    func getChats() {
        print("getting chats")
        let params = [
            "roomId": authViewModel.room_id
        ]
        Functions.functions().httpsCallable("getChats").call(params) { (result, error) in
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
                // Deserialize the 'history' key into an array of dictionaries
                if let historyArray = data["history"] as? [[String: Any]] {
                    // Clear chat data
                    self.chats.removeAll()
                    // Iterate over each chat dictionary in the history array
                    for chatDict in historyArray {
                        // Extract values and append a new Chat object
                        
                        if let role = chatDict["role"] as? String,
                           let message = chatDict["content"] as? String,
                           let isoString = chatDict["createdAt"] as? String,
                           let timestamp = ChatStore.dateFormatter.date(from: isoString) {
                            if role == "assistant" {
                                self.chats.append(
                                    Chat(
                                        username: "HouseKeeper",
                                        message: message,
                                        timestamp: timestamp
                                    )
                                )
                            }
                            else {
                                if let username = chatDict["displayName"] as? String{
                                    self.chats.append(
                                        Chat(
                                            username: username,
                                            message: message,
                                            timestamp: timestamp
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                print("Error getting chats")
            }
        }
    }
}
