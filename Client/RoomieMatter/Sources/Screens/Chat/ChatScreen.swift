//
//  ChatScreen.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

struct ChatScreen: View {
    @StateObject var store = ChatStore.shared
    @State private var textInput: String = ""
    @State private var authViewModel = AuthenticationViewModel.shared
    @State private var doNotScroll = false
    @State private var topChatAnchor: Chat? = nil

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                ForEach(store.chats, id: \.id) { chat in
                    TextBubble(chat: chat,
                               position: chat.username == authViewModel.username ? .right : .left)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                }
                .onAppear {
                    scrollToBottom(scrollViewProxy)
                }
                .onChange(of: store.idSet) {
                    scrollToBottom(scrollViewProxy)
                }
            }
            .listStyle(.plain)
            .navigationTitle(authViewModel.roomname ?? "failed_to_fetch_roomname")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                doNotScroll = true
                topChatAnchor = store.chats.first
                store.getChats()
            }
        }
        
        HStack {
            TextField("Enter your message", text: $textInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                print("Message sent: \(textInput)")
                store.sendChat(msg: textInput)
                textInput = ""
            }) {
                Text("Send")
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    func scrollToBottom(_ scrollViewProxy: ScrollViewProxy) {
        if !doNotScroll {
            withAnimation(.easeOut(duration: 0.5)) {
                if let lastChat = store.chats.last {
                    scrollViewProxy.scrollTo(lastChat.id, anchor: .bottom)
                }
            }
        }
        else {
            doNotScroll.toggle()
            if let topChatAnchor = topChatAnchor {
                scrollViewProxy.scrollTo(topChatAnchor.id, anchor: .top)
            }
        }
        
    }
}

//#Preview {
//    ChatScreen()
//}
