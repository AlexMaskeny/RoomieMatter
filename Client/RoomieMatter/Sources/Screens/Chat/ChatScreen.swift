//
//  ChatScreen.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

struct ChatScreen: View {
    private let store = ChatStore.shared
    @State private var isPresenting = false
    @State private var textInput: String = ""
    @State private var authViewModel = AuthenticationViewModel()

    var body: some View {
        List(store.chats.indices, id: \.self) {
            TextBubble(chat: store.chats[$0],
                       position: store.chats[$0].username == authViewModel.username ? .left : .right)
        }
        .listStyle(.plain)
        .refreshable {
            //store.getChats()  TODO: uncomment after defining getChats()
        }
        .navigationTitle("room_name_placeholder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement:.navigationBarTrailing) {
                Button {
                    isPresenting.toggle()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .navigationDestination(isPresented: $isPresenting) {
            PostView(isPresented: $isPresenting)
        }
        
        HStack {
            TextField("Enter your message", text: $textInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                print("Message sent: \(textInput)")
                textInput = ""
                // store.postChat(...)  TODO: uncomment after defining postChat(), and delete PostView file
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
