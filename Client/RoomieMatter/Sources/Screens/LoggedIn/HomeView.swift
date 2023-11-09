
import SwiftUI

struct HomeView: View {
    let roommates = [Roommate.Example2,  Roommate.Example3,  Roommate.Example4]
    let chores = [Chore.Example1, Chore.Example2]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading){
                RoommateStatusView(isSelf: true, roommate: Roommate.Example1)
                Divider()
                ForEach(roommates, id: \.name){ roommate in
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
                        ForEach(chores, id:\.name){ chore in
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