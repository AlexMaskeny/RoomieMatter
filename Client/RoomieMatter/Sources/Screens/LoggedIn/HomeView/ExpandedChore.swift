import SwiftUI
import FirebaseFunctions
import GoogleSignIn

struct ExpandedChore: View {
    var chore: Chore
    var roommates: [Roommate]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var loggedInViewViewModel: LoggedInViewViewModel
    @State private var showing = true

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text(chore.name)
                                .font(.title)
                                .bold()
                                .foregroundStyle(.roomieMatter)

                            Group {
                                if Calendar.current.isDateInToday(Date(timeIntervalSince1970: chore.date)) {
                                    Text("Today")
                                        .font(.subheadline)
                                        
                                } else if Calendar.current.isDateInTomorrow(Date(timeIntervalSince1970: chore.date)) {
                                    Text("Tomorrow")
                                        .font(.subheadline)
                                        
                                } else {
                                    Text(Date(timeIntervalSince1970: chore.date), format: .dateTime.weekday())
                                        .font(.subheadline)
                                        
                                }
                                Spacer()
                                    .frame(height: 20)
                                Text(chore.description)
                                    
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
                        .padding(.horizontal)


                        HStack {
                            Group {
                                if let image = chore.author.image {
                                    image
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .scaledToFill()
                                        .overlay(
                                            Circle()
                                                .stroke()
                                        )
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.headline)
                                        .padding(10)
                                        .background(
                                            Circle()
                                                .foregroundStyle(.white)
                                                .overlay(
                                                    Circle()
                                                        .stroke()
                                                )
                                        )
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Circle()
                                    .frame(width: 15)
                                    .foregroundStyle(chore.author.status.color)
                            }

                            VStack(alignment: .leading) {
                                Text("Created by:")
                                    .multilineTextAlignment(.leading)
                                Text(chore.author.displayName)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
                        .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("Assignees:")
                    ForEach(chore.assignedRoommates) { roommate in
                        HStack{
                            Group{
                                if let image = roommate.image{
                                    image
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .scaledToFill()
                                        .overlay(
                                            Circle()
                                                .stroke()
                                        )
                                    
                                } else{
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .padding()
                                        .background(
                                            Circle()
                                                .foregroundStyle(.gray.opacity(0.3))
                                                .overlay(
                                                    Circle()
                                                        .stroke()
                                                )
                                        )
                                }
                            }
                            .overlay(alignment: .bottomTrailing){
                                Circle()
                                    .frame(width: 15)
                                    .foregroundStyle(roommate.status.color)
                                    .overlay(
                                        Circle()
                                            .stroke()
                                    )
                            }
                            .padding(.horizontal)
                            
                            
                            
                            VStack(alignment: .leading, spacing: 8){
                                HStack {
                                    Text(roommate.displayName)
                                        .font(.headline)
                                        .bold()
                                }
                                Text(roommate.status.status)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                
                            }
                            Spacer()
                            
                            
                        }
                    }
                }
                Spacer()
                Button(action: {
                                    // Add your action here
                                    print("Chore completed!")
                                }) {
                                    Text("Complete Chore")
                                        .font(.title2)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                .padding()
            }
            .onChange(of: showing, { oldValue, newValue in
                if newValue == false{
                    dismiss()
                }
            })
            .toolbar{
                NavigationLink{
                    EditChoreView(loggedInViewViewModel: loggedInViewViewModel, chore: chore, showing: $showing)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    func completeEvent(){
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not properly signed in")
            return
        }
        
        let token = user.accessToken.tokenString
        
        let data = ["token": token, "instanceId": chore.id,"roomId": AuthenticationViewModel.shared.room_id ?? ""]
        
        Functions.functions().httpsCallable("completeChore").call(data) { (result, error) in
                print("in completeChore")
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        print("Error: \(message)")
                    }
                    // Handle the error
                }
                if let data = result?.data as? [String: Any] {
                    print(data)
                }
            }
    }
}


