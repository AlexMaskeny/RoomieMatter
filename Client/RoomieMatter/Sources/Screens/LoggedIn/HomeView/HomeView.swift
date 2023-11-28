
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @StateObject var homeViewViewModel:HomeViewViewModel
    
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
                        AddChoreView(roommates: homeViewViewModel.roommates)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(2)
                            .background(
                                Circle()
                                    .foregroundStyle(.roomieMatter)
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
                            NavigationLink{
                                ExpandedChore(chore: chore, roommates: homeViewViewModel.roommates)
                            }label: {
                                ChoreView(chore: chore)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack {
                    Text("My Chores")
                        .font(.title)
                        .bold()
                        .padding()
                    NavigationLink {
                        AddChoreView(roommates: homeViewViewModel.roommates)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(2)
                            .background(
                                Circle()
                                    .foregroundStyle(.roomieMatter)
                            )
                    }
                    Spacer()
                    NavigationLink("View All") {
                        AllChores(chores: homeViewViewModel.myChores)
                    }
                    .padding()
                }
                ScrollView(.horizontal){
                    HStack{
                        ForEach(homeViewViewModel.myChores){ chore in
                            NavigationLink{
                                ExpandedChore(chore: chore, roommates: homeViewViewModel.roommates)
                            }label: {
                                ChoreView(chore: chore)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    init(chores:[Chore], events:[Chore]){
        self._homeViewViewModel = StateObject(wrappedValue: HomeViewViewModel(chores: chores, events: events))
    }
}

#Preview {
    HomeView(chores: [Chore.Example1, Chore.Example2], events: [Chore.Example1, Chore.Example2])
}
