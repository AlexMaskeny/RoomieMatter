

import SwiftUI

struct LoggedInView: View {
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
                
                ProfileView(isSelf: true, roommate: Roommate.Example1)
                    .tabItem {
                        Image(systemName: "person.fill")
                    }
            }
            
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading) {
                    Text("Name of Room")
                        .font(.title)
                        .foregroundStyle(.white)
                    
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        Text("Chat View")
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

#Preview {
    LoggedInView()
}
