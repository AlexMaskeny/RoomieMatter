import SwiftUI
import Firebase

@main
struct RoomieMatterApp: App {
    
    init() {
        print("Configuring Firebase...")
        FirebaseApp.configure()
    }
    
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                InitialScreen()
            }
        }
    }
}
