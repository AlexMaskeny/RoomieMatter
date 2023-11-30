
import FirebaseAuth
import FirebaseFirestore
import Firebase
import SwiftUI

struct LoggedInView: View {
    @StateObject var viewModel = LoggedInViewViewModel()
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
                    NavigationLink {
                        SyncCalendarView()
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.white)
                    }
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



