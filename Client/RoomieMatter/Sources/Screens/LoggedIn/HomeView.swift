
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @StateObject var homeViewViewModel = HomeViewViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading){
                RoommateStatusView(isSelf: true, roommate: Roommate.Example1)
                Divider()
                ForEach(homeViewViewModel.roommates){ roommate in
                    RoommateStatusView(isSelf: false, roommate: roommate)
                    Divider()
                }
                
                HStack {
                    Text("Chore Tracking")
                        .font(.title)
                        .bold()
                        .padding()
                    NavigationLink {
                        Text("Add Chore View")
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(2)
                            .background(
                                Circle()
                                    .foregroundStyle(.blue)
                            )
                    }
                    Spacer()
                    NavigationLink("View All") {
                        Text("View All Chore View")
                    }
                    .padding()
                }
                ScrollView(.horizontal){
                    HStack{
                        ForEach(homeViewViewModel.chores){ chore in
                            ChoreView(chore: chore)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
}

#Preview {
    HomeView()
}
