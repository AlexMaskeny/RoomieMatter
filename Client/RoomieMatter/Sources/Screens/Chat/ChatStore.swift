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

    //  Placeholders
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    private(set) var chats: [Chat] = [
        Chat(username: "Alex David Maskeny", message: "Hi there!", timestamp: dateFormatter.date(from: "2023-11-02T15:30:00")),
            Chat(username: "David Wang", message: "Hello World!", timestamp: dateFormatter.date(from: "2023-11-02T15:30:00")),
        ]
    
    func sendChat(msg: String) {
           let params = [
               "userId": "ALfAiMtHmWhfUgaSQWGIUHUujUs1",
               "roomId": "ymHbFA1lhmBJMyHARUMk",
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
               if let data = result?.data as? [String: Any] {
                   print(data)
               }
           }
       }

}
