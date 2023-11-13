
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @StateObject var homeViewViewModel = HomeViewViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading){
                RoommateStatusView(isSelf: true, roommate: homeViewViewModel.user)
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
                        AddChoreView()
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
                        AllChores(chores: homeViewViewModel.chores)
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
