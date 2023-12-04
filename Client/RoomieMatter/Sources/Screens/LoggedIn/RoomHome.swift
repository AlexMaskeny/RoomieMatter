//
//  RoomHome.swift
//  RoomieMatter
//
//  Created by Tanuj Koli on 12/3/23.
//

import Foundation
import SwiftUI

import SwiftUI

//struct ContentView: View {
//    @State private var isNextViewActive = false
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Hello, SwiftUI!")
//                
//                // Hidden NavigationLink with a hidden button
//                NavigationLink("", destination: NextView(), isActive: $isNextViewActive)
//                    .opacity(0)
//                    .frame(width: 0, height: 0)
//
//                // Actual button to trigger navigation
//                Button(action: {
//                    isNextViewActive = true
//                }) {
//                    Text("Go to Next View")
//                }
//            }
//            .navigationBarTitle("Main View", displayMode: .inline)
//        }
//    }
//}
//
//struct NextView: View {
//    var body: some View {
//        Text("This is the Next View")
//            .navigationBarTitle("Next View", displayMode: .inline)
//    }
//}
//
//@main
//struct YourApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


struct RoomHome: View {
    @State private var isJoinViewActive = false
    @State private var isCreateViewActive = false
    var body: some View {
        
        VStack {
            // Banner with RoomieMatter text, notification bell, and profile icons
            HStack {
                Spacer()
//                Button(action: {
//                    // Handle navigation to notifications
//                    print("Notifications tapped")
//                }) {
//                    Image(systemName: "bell")
//                        .font(.title)
//                        .foregroundColor(.white)
//                        .padding(.trailing, 10)
//                }
//                Button(action: {
//                    // Handle navigation to profile
//                    print("Profile tapped")
//                }) {
//                    Image(systemName: "person.circle")
//                        .font(.title)
//                        .foregroundColor(.white)
//                        .padding(.trailing, 16)
//                }
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(.roomieMatter)
                    .padding(.trailing, 16)
                
            }
            .padding()
            .background(Color.roomieMatter)
            
            // Your Rooms label
            Text("Welcome to RoomieMatter!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
//            // Current rooms tiles
//            ScrollView {
//                // Include your TileView here for each room
//                HStack {
//                    Spacer()
//                    TileView(creatorName: "Anish Sundaram", roomName: "1316 Geddes")
//                        .padding(.vertical, 8)
//                    Spacer()
//                }
//                
//                
//                // Add more TileView instances for each room
//                
//            }
//            
//            Spacer()
            
            VStack {
                // Create Room button as a rounded rectangle
                NavigationLink("", destination: JoinRoomView(), isActive: $isJoinViewActive)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                Button(action: {
                    // Handle the action for creating a room
                    isJoinViewActive = true
                    print("Join Room tapped")
                }) {
                    Text(" Join Room ")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.roomieMatter))
                }
                NavigationLink("", destination: CreateRoomView(), isActive: $isCreateViewActive)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                Button(action: {
                    // Handle the action for creating a room
                    isCreateViewActive = true
                    print("Create Room tapped")
                }) {
                    Text("Create Room")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.roomieMatter))
                }
                Spacer()
            }
            
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct RoomHome_Previews: PreviewProvider {
    static var previews: some View {
        RoomHome()
    }
}
