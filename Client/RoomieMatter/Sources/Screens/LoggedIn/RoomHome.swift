import SwiftUI

struct RoomHome: View {
    @State private var isJoinViewActive = false
    @State private var isCreateViewActive = false
    @State private var err: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to\nRoomieMatter!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 50)
                .multilineTextAlignment(.center)
            
            // Join Room Button
            Button(action: {
                isJoinViewActive = true
                print("Join Room tapped")
            }) {
                buttonContent(text: "Join Room")
            }

            // Create Room Button
            Button(action: {
                isCreateViewActive = true
                print("Create Room tapped")
            }) {
                buttonContent(text: "Create Room")
            }

            // Log Out Button
            Button(action: {
                Task {
                    do {
                        try await Authentication().logout()
                    } catch let e {
                        err = e.localizedDescription
                    }
                }
            }) {
                buttonContent(text: "Log Out")
            }

            Spacer()

            // Hidden NavigationLink for Join Room
            NavigationLink("", destination: JoinRoomView(), isActive: $isJoinViewActive)
                .opacity(0)
                .frame(width: 0, height: 0)

            // Hidden NavigationLink for Create Room
            NavigationLink("", destination: CreateRoomView(), isActive: $isCreateViewActive)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .edgesIgnoringSafeArea(.all)
    }

    // Helper function to create button content
    private func buttonContent(text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(.headline)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.roomieMatter))
        .frame(width: 200, height: 50)
    }
}

struct RoomHome_Previews: PreviewProvider {
    static var previews: some View {
        RoomHome()
    }
}
