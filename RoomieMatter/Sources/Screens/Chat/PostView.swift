//
//  PostView.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

struct PostView: View {
    @Binding var isPresented: Bool

    private let username = "davidwxy"
    @State private var message = "Some short sample text."
    
    var body: some View {
        VStack {
            Text(username)
                .padding(.top, 30.0)
            TextEditor(text: $message)
                .padding(EdgeInsets(top: 10, leading: 18, bottom: 0, trailing: 4))
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement:.navigationBarTrailing) {
                SubmitButton()
            }
        }
    }
    
    @ViewBuilder
    func SubmitButton() -> some View {
        Button {
            ChatStore.shared.postChat(Chat(username: username, message: message)) {
                ChatStore.shared.getChats()
        }
            isPresented.toggle()
        } label: {
            Image(systemName: "paperplane")
        }
    }
}
