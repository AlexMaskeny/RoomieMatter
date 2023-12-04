//
//  CreateRoomView.swift
//  RoomieMatter
//
//  Created by Lasya Mantha on 12/3/23.
//

import SwiftUI

struct CreateRoomView: View {
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
                    print("Room Created")
                    self.showShareSheet = true
                }) {
                    Text("Create Room")
                }
            }
            .navigationBarTitle("Create a New Room")
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: ["Join my room: \(roomName) on RoomieMatter!"])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CreateRoomView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRoomView()
    }
}

