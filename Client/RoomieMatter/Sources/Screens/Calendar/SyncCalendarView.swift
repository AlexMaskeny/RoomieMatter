//
//  SyncCalendarView.swift
//  RoomieMatter
//
//  Created by Anish Sundaram on 11/27/23.
//

import Foundation
import SwiftUI

struct SyncCalendarView: View {
    @State private var enableNotifications = false
    @State private var syncEvents = false
    @State private var syncChoreTasks = false
    @State private var authViewModel = AuthenticationViewModel.shared

    var body: some View {
            ScrollView{
                VStack() {
                    // notifs
                    HStack {
                        Image(systemName: "bell")
                            .frame(width: 30, alignment: .leading) // Adjust the width as needed
                        Text("Enable All Notifications")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)
                        Spacer()
                        Toggle(isOn: $enableNotifications) {}
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 16)
                    .overlay(Divider().background(Color.black), alignment: .bottom)

                    // event sync
                    HStack {
                        Image(systemName: "calendar")
                            .frame(width: 30, alignment: .leading) // Adjust the width as needed
                        Text("Sync Events")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Toggle(isOn: $syncEvents) {}
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 16)
                    .overlay(Divider().background(Color.black), alignment: .bottom)

                    // chore sync
                    HStack {
                        Image(systemName: "hammer")
                            .frame(width: 30, alignment: .leading) // Adjust the width as needed
                        Text("Sync Chore Tasks")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Toggle(isOn: $syncChoreTasks) {}
                    }
                    .padding(.bottom, 8)
                    .padding(.horizontal, 16)
                    .overlay(Divider().background(Color.black), alignment: .bottom)
                    
                    Spacer()

                    SyncButton(title: "Sync to Google Calendar", backgroundColor: .roomieMatter) {
                        // Add your sync to Google Calendar logic here
                        print("syncEvents: ", syncEvents, "syncChoreTasks: ", syncChoreTasks)
                    }
                    
                    Spacer()
                }
                .padding()
                .toolbarBackground(Color.roomieMatter)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Sync to Google Calendar")
                            .font(.headline)  // Adjust the font size as needed
                            .foregroundColor(.white)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
    }
    
    struct SyncButton: View {
        let title: String
        let backgroundColor: Color
        let action: () -> Void
        
        var body: some View {
            Button {
                action()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(backgroundColor)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .bold()
                        .padding(.vertical, 10)
                }
            }.frame(maxHeight: .infinity , alignment: .bottom)
        }
    }
}

#Preview {
    SyncCalendarView()
}
