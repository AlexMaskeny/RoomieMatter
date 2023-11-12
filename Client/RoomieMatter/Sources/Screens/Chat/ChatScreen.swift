//
//  ChatScreen.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

struct ChatScreen: View {
    private let store = ChatStore.shared
    @State private var textInput: String = ""
    @State private var authViewModel = AuthenticationViewModel()

    var body: some View {
        List(store.chats.indices, id: \.self) {
            TextBubble(chat: store.chats[$0],
                       position: store.chats[$0].username == authViewModel.username ? .left : .right)
            .listRowSeparator(.hidden)
            
            .listRowInsets(.init(top: 0, leading: 0, bottom: 5, trailing: 0))
        }
        .listStyle(.plain)
        .refreshable {
            //store.getChats()  TODO: uncomment after defining getChats()
        }
        .navigationTitle(authViewModel.roomname ?? "failed_to_fetch_roomname")
        .navigationBarTitleDisplayMode(.inline)
        
        HStack {
            TextField("Enter your message", text: $textInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                print("Message sent: \(textInput)")
                store.sendChat(msg: textInput)  //TODO: uncomment after defining postChat(), and delete PostView file
                textInput = ""
            }) {
                Text("Send")
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    ChatScreen()
}
