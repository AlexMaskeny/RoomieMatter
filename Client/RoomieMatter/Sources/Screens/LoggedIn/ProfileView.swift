import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct ProfileView: View {
    @State private var isLoggedOut = false
    @State private var err : String = ""
    @State private var showRoomHome : Bool = false
    let isSelf: Bool
    let roommate: Roommate
    let authViewModel = AuthenticationViewModel.shared
    
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
                        print(editStatus(status: selectedStatus))
                    }
                }
                
                
                
                .frame(height: geometry.size.height * 0.3)

                Spacer()
                    .frame(height: 300)
                
                Button{
                    authViewModel.fetchUser(){
                        authViewModel.fetchRoom(){
                            let params = [
                                "roomId": authViewModel.room_id,
                                "userId": authViewModel.user_uid
                            ]
                            Functions.functions().httpsCallable("quitRoom").call(params) { (result, error) in
                                if let error = error as NSError? {
                                    if error.domain == FunctionsErrorDomain {
                                        let code = FunctionsErrorCode(rawValue: error.code)
                                        let message = error.localizedDescription
                                        let details = error.userInfo[FunctionsErrorDetailsKey]
                                        print("Error: \(String(describing: code)) \(message) \(String(describing: details))")
                                    }
                                }
                                
                                if let data = result?.data as? [String: Any] {
                                    if let success = data["success"] as? Bool {
                                        if success {
                                            print("Room quit success")
                                            showRoomHome = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }label: {
                    Text("Leave Room").padding(8)
                        .font(.system(size: 25))
                    
                }.padding(5)
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                .fullScreenCover(isPresented: $showRoomHome) {
                    NavigationStack {
                        RoomHome()
                    }
                }

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

//#Preview {
//    ProfileView(isSelf: true, roommate: Roommate.Example1)
//}
