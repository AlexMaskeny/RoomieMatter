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

    var body: some View {
        List(store.chats.indices, id: \.self) {
            ChatListRow(chat: store.chats[$0])
                .listRowSeparator(.hidden)
                .listRowBackground(Color(($0 % 2 == 0) ? .systemGray5 : .systemGray6))
        }
        .listStyle(.plain)
        .refreshable {
            //store.getChats()
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
