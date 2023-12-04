import Foundation
import FirebaseFunctions
import SwiftUI

struct JoinRoomView: View {
    @State private var roomToken: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showLoggedInView = false
    let authViewModel = AuthenticationViewModel.shared

    var body: some View {
        NavigationView {
            VStack {
                Text("Join Room")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                    .multilineTextAlignment(.center)
                
                Spacer()
                Form {
                    Section(header: Text("Room Token")) {
                        TextField("Room Token", text: $roomToken)
                    }
                    
                    Button("Join Room") {
                        joinRoom()
                    }
                    .disabled(roomToken.isEmpty)
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
                .fullScreenCover(isPresented: $showLoggedInView, content: LoggedInView.init)
            }
        }
    }

    private func joinRoom() {
        // Show loading indicator or disable UI here if needed
        authViewModel.fetchUser() {
            Functions.functions().httpsCallable("joinRoom").call([
                "roomId": roomToken,
                "userId": authViewModel.user_uid
            ]) {(result, error) in

                if let error = error as NSError? {
                    self.alertMessage = "Error: \(error.localizedDescription)"
                    self.showingAlert = true
                    return
                }
                
                if let data = result?.data as? [String: Any], let success = data["success"] as? Bool, success {
                    self.showLoggedInView = true
                } else {
                    self.alertMessage = "Failed to join room."
                    self.showingAlert = true
                }
            }
        }
    }
}

struct JoinRoomView_Previews: PreviewProvider {
    static var previews: some View {
        JoinRoomView()
    }
}
