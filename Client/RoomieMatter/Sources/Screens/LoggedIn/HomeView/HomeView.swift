
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @ObservedObject var loggedInViewViewModel: LoggedInViewViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading){
                RoommateStatusView(isSelf: true, roommate: loggedInViewViewModel.user)
                Divider()
                    .onChange(of: AuthenticationViewModel.shared.room_id) { _, _ in
                        loggedInViewViewModel.getChores1()
                        loggedInViewViewModel.getEvents1()
                    }
                ForEach(loggedInViewViewModel.roommates){ roommate in
                    RoommateStatusView(isSelf: false, roommate: roommate)
                    Divider()
                }
                
                Group{
                    CustomButton(title: "Update Chores", backgroundColor: .roomieMatter) {
                        loggedInViewViewModel.getChores1()
                    }
                    .padding(.horizontal)
                    HStack {
                        Text("Chore Tracking")
                            .font(.title)
                            .bold()
                            .padding()
                        NavigationLink {
                            AddChoreView(loggedInViewViewModel: loggedInViewViewModel)
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
                                    ExpandedChore(chore: chore, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                            AddChoreView(loggedInViewViewModel: loggedInViewViewModel)
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
                            AllChores(chores: loggedInViewViewModel.myChores)
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.myChores){ chore in
                                NavigationLink{
                                    ExpandedChore(chore: chore, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                    CustomButton(title: "Update Events", backgroundColor: .roomieMatter) {
                        loggedInViewViewModel.getEvents1()
                    }
                    .padding(.horizontal)
                    HStack {
                        Text("All Events")
                            .font(.title)
                            .bold()
                            .padding()
                        NavigationLink {
                            AddEventView(loggedInViewViewModel: loggedInViewViewModel)
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
                            AllEvents(events: loggedInViewViewModel.events)
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.events){ event in
                                NavigationLink{
                                    EventInfo(event: event, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
                            AddEventView(loggedInViewViewModel: loggedInViewViewModel)
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
                            AllEvents(events: loggedInViewViewModel.myEvents)
                        }
                        .padding()
                    }
                    
                    ScrollView(.horizontal){
                        HStack{
                            ForEach(loggedInViewViewModel.myEvents){ event in
                                NavigationLink{
                                    EventInfo(event: event, roommates: loggedInViewViewModel.roommates, loggedInViewViewModel: loggedInViewViewModel)
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
    
}
