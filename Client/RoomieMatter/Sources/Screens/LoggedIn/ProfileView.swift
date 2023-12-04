import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var isLoggedOut = false
    @State private var err : String = ""
    let isSelf: Bool
    let roommate: Roommate
    
    @State private var selectedStatus = "At Home"
        let statusOptions = ["At Home", "Sleeping", "In Class", "Not Home"]

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
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

//                        Group{
//                            Text(roommate.status.status)
//                                .font(.title3)
//                                .foregroundStyle(.gray)
//                                .multilineTextAlignment(.center)
//                        }
                        
                        Spacer()
                            .frame(width: 40)
                        
                        Circle()
                            .frame(width: 25)
                            .foregroundStyle(roommate.status.color)
                            .overlay(
                                Circle()
                                    .stroke()
                            )
                        
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
