//
//  ChatListRow.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

struct ChatListRow: View {
    let chat: Chat
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let username = chat.username, let timestamp = chat.timestamp {
                    Text(username).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
                    Spacer()
                    Text(timestamp).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
                }
            }
            if let message = chat.message {
                Text(message).padding(EdgeInsets(top: 8, leading: 0, bottom: 6, trailing: 0))
            }
        }
    }
}
