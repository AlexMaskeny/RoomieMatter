//
//  ChatStore.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

import Observation

@Observable
final class ChatStore {
    static let shared = ChatStore() // create one instance of the class to be shared
    private init() {}                // and make the constructor private so no other
                                     // instances can be created

    private(set) var chats = [Chat]()
    private let nFields = Mirror(reflecting: Chat()).children.count

    private let serverUrl = "https://18.221.221.145/"
    
    func getChats() {  // TODO: Work on this after server setup
//            guard let apiUrl = URL(string: serverUrl+"getchats/") else {
//                print("getChats: Bad URL")
//                return
//            }
//            
//            var request = URLRequest(url: apiUrl)
//            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept") // expect response in JSON
//            request.httpMethod = "GET"
//
//            URLSession.shared.dataTask(with: request) { data, response, error in
//                guard let data = data, error == nil else {
//                    print("getChats: NETWORKING ERROR")
//                    return
//                }
//                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
//                    print("getChats: HTTP STATUS: \(httpStatus.statusCode)")
//                    return
//                }
//                
//                guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
//                    print("getChats: failed JSON deserialization")
//                    return
//                }
//                let chatsReceived = jsonObj["chats"] as? [[String?]] ?? []
//                
//                DispatchQueue.main.async {
//                    self.chats = [Chat]()
//                    for chatEntry in chatsReceived {
//                        if chatEntry.count == self.nFields {
//                            self.chats.append(Chat(username: chatEntry[0],
//                                                    message: chatEntry[1],
//                                                    timestamp: chatEntry[2]))
//                        } else {
//                            print("getChats: Received unexpected number of fields: \(chatEntry.count) instead of \(self.nFields).")
//                        }
//                    }
//                }
//            }.resume()
            chats = [
                Chat(username: "User1", message: "Hello!", timestamp: "9:00 AM"),
                Chat(username: "User2", message: "Hi there!", timestamp: "9:05 AM"),
                Chat(username: "User1", message: "How are you?", timestamp: "9:10 AM"),
            ]
        }
    
    func postChat(_ chat: Chat, completion: @escaping () -> ()) {
            let jsonObj = ["username": chat.username,
                           "message": chat.message]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
                print("postChat: jsonData serialization error")
                return
            }
                    
            guard let apiUrl = URL(string: serverUrl+"postchat/") else {
                print("postChat: Bad URL")
                return
            }
            
            var request = URLRequest(url: apiUrl)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {
                    print("postChat: NETWORKING ERROR")
                    return
                }

                if let httpStatus = response as? HTTPURLResponse {
                    if httpStatus.statusCode != 200 {
                        print("postChat: HTTP STATUS: \(httpStatus.statusCode)")
                        return
                    } else {
                        completion()
                    }
                }

            }.resume()
        }
}

