

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
                
                Text("Profile View")
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
            .toolbarBackground(.blue)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    LoggedInView()
}
