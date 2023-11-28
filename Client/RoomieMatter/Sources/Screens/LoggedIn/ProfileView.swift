import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var isLoggedOut = false
    @State private var err : String = ""
    let isSelf: Bool
    let roommate: Roommate

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    Group{
                        Text(getChores())
                        Spacer()
                        
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
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.center)
                        }

                        Group{
                            Text(roommate.status.status)
                                .font(.title3)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                            .frame(width: 40)
                        
                        Circle()
                            .frame(width: 20)
                            .foregroundStyle(roommate.status.color)
                            .overlay(
                                Circle()
                                    .stroke()
                            )
                        
                    }
                }
                .frame(height: geometry.size.height * 0.3)

                Spacer()

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
                }.buttonStyle(.borderedProminent)
                    .frame(height: geometry.size.height * 0.1, alignment: .bottom)
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
