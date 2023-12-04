
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    //@StateObject var homeViewViewModel:HomeViewViewModel
    @EnvironmentObject var loggedInViewViewModel: LoggedInViewViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading){
                Button{
                    loggedInViewViewModel.getChores1()
                } label: {
                    Text("Get chores")
                }
                .onChange(of: AuthenticationViewModel.shared.room_id) { oldValue, newValue in
                    print("room id set now \(newValue)")
                }
                Button{
                    //getEvents()
                    loggedInViewViewModel.getEvents1()
                } label: {
                    Text("Get Events")
                }
                RoommateStatusView(isSelf: true, roommate: loggedInViewViewModel.user)
                Divider()
                ForEach(loggedInViewViewModel.roommates){ roommate in
                    RoommateStatusView(isSelf: false, roommate: roommate)
                    Divider()
                }
                
                Group{
                    HStack {
                        Text("Chore Tracking")
                            .font(.title)
                            .bold()
                            .padding()
                        NavigationLink {
                            AddChoreView(author: loggedInViewViewModel.user, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                            AllChores(chores: loggedInViewViewModel.chores)
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.chores){ chore in
                                NavigationLink{
                                    ExpandedChore(chore: chore, roommates: loggedInViewViewModel.roommates)
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
                            AddChoreView(author: loggedInViewViewModel.user, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                            AllChores(chores: loggedInViewViewModel.myChores)
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.myChores){ chore in
                                NavigationLink{
                                    ExpandedChore(chore: chore, roommates: loggedInViewViewModel.roommates)
                                }label: {
                                    ChoreView(chore: chore)
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Group{
                    HStack {
                        Text("All Events")
                            .font(.title)
                            .bold()
                            .padding()
                        NavigationLink {
                            AddEventView(author: loggedInViewViewModel.user, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                            Text("View all events")
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.events){ event in
                                NavigationLink{
                                    EventInfo(event: event, roommates: loggedInViewViewModel.roommates)
                                    //EditEventView(roommates: homeViewViewModel.roommates, event: event)
                                }label: {
                                    EventView(event: event)
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("My Events")
                            .font(.title)
                            .bold()
                            .padding()
                        NavigationLink {
                            AddEventView(author: loggedInViewViewModel.user, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                        NavigationLink("View Mine") {
                            Text("View all my events")
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.myEvents){ event in
                                NavigationLink{
                                    EventInfo(event: event, roommates: loggedInViewViewModel.roommates)
                                }label: {
                                    EventView(event: event)
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
    }
    
    init(chores:[Chore], events:[Event]){
//        self._homeViewViewModel = StateObject(wrappedValue: HomeViewViewModel(chores: chores, events: events))
    }
}

#Preview {
    HomeView(chores: [Chore.Example1, Chore.Example2], events: [Event.Example1, Event.Example2])
}
