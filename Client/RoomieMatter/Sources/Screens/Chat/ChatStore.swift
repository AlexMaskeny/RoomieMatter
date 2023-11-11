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

}
