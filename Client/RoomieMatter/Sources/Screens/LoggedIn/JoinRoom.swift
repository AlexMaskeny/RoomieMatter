//
//  JoinRoom.swift
//  RoomieMatter
//
//  Created by Tanuj Koli on 12/3/23.
//

import Foundation


import SwiftUI

struct JoinRoomView: View {
    @State private var creatorName: String = ""
    @State private var roomName: String = ""
    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Room Information")) {
                    TextField("Creator Name", text: $creatorName)
                    TextField("Room Name", text: $roomName)
                }
                Button(action: {
                    print("Room Joined")
                    self.showShareSheet = true
                }) {
                    Text("Join Room")
                }
            }
            .navigationBarTitle("Join a New Room")
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: ["Join my room: \(roomName) on RoomieMatter!"])
            }
        }
    }
}

struct JoinRoomView_Previews: PreviewProvider {
    static var previews: some View {
        JoinRoomView()
    }
}
