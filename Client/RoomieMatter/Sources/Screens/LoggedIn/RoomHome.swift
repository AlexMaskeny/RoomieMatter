//
//  RoomHome.swift
//  RoomieMatter
//
//  Created by Tanuj Koli on 12/3/23.
//

import Foundation
import SwiftUI

struct RoomHome: View {
    var body: some View {
        VStack {
            // Banner with RoomieMatter text, notification bell, and profile icons
            HStack {
                Spacer()
                Image(systemName: "bell")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.trailing, 16)
            }
            .padding()
            .background(Color.roomieMatter)
            
            // Your Rooms label
            Text("Your Rooms")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            // Current rooms tiles
            ScrollView {
                // Include your TileView here for each room
                TileView(creatorName: "Anish Sundaram", roomName: "1316 Geddes")
                    .padding(.vertical, 8)
                
                // Add more TileView instances for each room
                
            }
            
            Spacer()
            
            // Create Room button as a rounded rectangle
            Button(action: {
                // Handle the action for creating a room
                print("Create Room tapped")
            }) {
                Text("Create Room")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.roomieMatter))
            }
            .padding()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct RoomHome_Previews: PreviewProvider {
    static var previews: some View {
        RoomHome()
    }
}