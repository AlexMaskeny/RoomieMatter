import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var isLoggedOut = false
    @State private var err : String = ""
    let authViewModel = AuthenticationViewModel.shared
    let isSelf: Bool
    let roommate: Roommate
    
    @State private var selectedStatus: String
    let statusOptions = ["At Home", "Sleeping", "Studying", "Not Home"]

    init(isSelf: Bool, roommate: Roommate) {
        self.isSelf = isSelf
        self.roommate = roommate
        _selectedStatus = State(initialValue: roommate.status.status)
    }
    
    struct ChangeStatusButton: View {
        let title: String
        let backgroundColor: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(backgroundColor)
                    Text(title)
                    .padding(8)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    Spacer().frame(height: 70)
                    Group{
                        if let image = roommate.image{
                            image
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .scaledToFill()
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)

                        } else{
                            Image(systemName: "person.fill")
                                .font(.title)
                                .padding()
                                .background(
                                    Circle()
                                        .foregroundStyle(.gray)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 10)
                                )
                        }
                    }

                    Group{
                        Text(roommate.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Divider()

                    HStack{
                        Group{
                            Text("User Status:")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.center)
                        }
                        
                        Picker(selection: $selectedStatus, label: Text("User Status")) {
                            ForEach(statusOptions, id: \.self) {
                                Text($0).font(.system(size: 20))
                            }
                        }
                        .pickerStyle(.menu)
                        .onAppear {
                            selectedStatus = roommate.status.status
                        }
                        
                        
                        Spacer()
                            .frame(width: 40)
                        
                        Circle()
                                .frame(width: 25, height: min(geometry.size.height * 0.3 - 70, 25)) 
                                .foregroundStyle(interpretString(status: selectedStatus.lowercased()).color)
                                .overlay(
                                    Circle()
                                        .stroke()
                                )
                        
                    }
                    
                    ChangeStatusButton(title: "Change Status", backgroundColor: .roomieMatter) {
                        // call editStatus()
                        print(editStatus(userID: authViewModel.user_uid, roomID: authViewModel.room_id, status: selectedStatus))
                        print(authViewModel.user_uid,authViewModel.room_id, selectedStatus)
                    }
                }
                
                
                
                .frame(height: geometry.size.height * 0.3)

                Spacer()
                    .frame(height: 300)
                
                Button{
                                    // Add leave room action here
                }label: {
                    Text("Leave Room").padding(8)
                        .font(.system(size: 25))
                    
                }.padding(5)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                Button{
                    Task {
                        do {
                            try await Authentication().logout()
                        } catch let e {
                            err = e.localizedDescription
                        }
                    }
                }label: {
                    Text("Log Out").padding(8)
                        .font(.system(size: 25))
                }.padding(5)
                    .frame(maxWidth: .infinity)
                    .background(Color.roomieMatter)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .alert(isPresented: $isLoggedOut) {
                Alert(title: Text("Logged Out"), message: Text("You have been logged out."), dismissButton: .default(Text("OK")))
            }
        }
    }
}

#Preview {
    ProfileView(isSelf: true, roommate: Roommate.Example1)
}
