import Foundation
import FirebaseFunctions


//initial commit
import SwiftUI

struct CreateRoomView: View {
    @State private var roomName: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showShareSheet: Bool = false
    @State private var showLoggedInView = false
    let authViewModel = AuthenticationViewModel.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Room Name")) {
                    TextField("Room Name", text: $roomName)
                }
                Button(action: {
                    createRoom()
                }) {
                    Text("Create Room")
                }
                .disabled(roomName.isEmpty)
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .navigationBarTitle("Create a New Room")
            .fullScreenCover(isPresented: $showLoggedInView, content: LoggedInView.init)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: ["Join my room: \(roomName) on RoomieMatter!"])
            }
        }
    }
    
    private func createRoom() {
        // Show loading indicator or disable UI here if needed

        Functions.functions().httpsCallable("createRoom").call([
            "roomName": roomName,
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

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CreateRoomView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRoomView()
    }
}

