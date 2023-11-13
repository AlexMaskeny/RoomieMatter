
import FirebaseAuth
import FirebaseFirestore
import Firebase
import SwiftUI

struct LoggedInView: View {
    @StateObject var viewModel = LoggedInViewViewModel()
    var body: some View {
        NavigationStack{
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                    }
                
                Text("Calendar View")
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
    }
}
func interpretString(status: String) -> Status{
    switch status{
    case "At Home":
        return .home
    case "Studying":
        return .studying
    case "In Class":
        return .inClass
    default:
        return .sleeping
    }
}


