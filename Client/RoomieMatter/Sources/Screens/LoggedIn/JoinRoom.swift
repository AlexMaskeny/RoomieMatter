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
            Form {
                Section(header: Text("Room Information")) {
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
            .navigationBarTitle("Join a New Room")
            .fullScreenCover(isPresented: $showLoggedInView, content: LoggedInView.init)
        }
    }

    private func joinRoom() {
        // Show loading indicator or disable UI here if needed

        Functions.functions().httpsCallable("joinRoom").call([
            "roomId": roomToken,
            "userId": authViewModel.user_uid
        ]) {(result, error) in
            // Hide loading indicator or enable UI here

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

struct JoinRoomView_Previews: PreviewProvider {
    static var previews: some View {
        JoinRoomView()
    }
}