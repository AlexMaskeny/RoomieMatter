
import FirebaseAuth
import FirebaseFirestore
import Firebase
import SwiftUI
import UIKit

func copyToClipboard(text: String) {
    let pasteboard = UIPasteboard.general
    pasteboard.string = text
}

struct LoggedInView: View {
    @StateObject var viewModel = LoggedInViewViewModel()
    @State private var showingAlert = false
    var body: some View {
        NavigationStack{
            TabView {
                HomeView(chores: viewModel.chores, events: viewModel.events)
                    .tabItem {
                        Image(systemName: "house")
                    }
                
                CalendarView()
                    .tabItem {
                        Image(systemName: "calendar")
                    }
                
                ProfileView(isSelf: true, roommate: viewModel.user)
                    .tabItem {
                        Image(systemName: "person.fill")
                    }
            }
            
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading) {
                    Text(viewModel.roomName)
                        .font(.title)
                        .foregroundStyle(.white)
                    
                }
                
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
//                    Button(action: {
//                                copyToClipboard(text: "Join my room: \(viewModel.roomName) on RoomieMatter!")
//                            }) {
//                                Image(systemName: "clipboard")
//                                    .foregroundStyle(.white)
//                            }
                    Button(action: {
                                            copyToClipboard(text: "Join my room: \(viewModel.roomName) on RoomieMatter!")
                                            self.showingAlert = true
                                        }) {
                                            Image(systemName: "clipboard")
                                                .foregroundStyle(.white)
                                        }
                                        .alert(isPresented: $showingAlert) {
                                            Alert(title: Text("Copied"), message: Text("Join room info has been copied to clipboard"), dismissButton: .default(Text("Got it!")))
                                        }
//                    NavigationLink {
//                        SyncCalendarView()
//                    } label: {
//                        Image(systemName: "calendar")
//                            .foregroundStyle(.white)
//                    }
                    
                    NavigationLink {
                        ChatScreen()
                    } label: {
                        Image(systemName: "ellipsis.message")
                            .foregroundStyle(.white)
                    }
                }
                
            }
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }
}
