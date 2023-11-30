import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

@main
struct RoomieMatterApp: App {
    init() {
        print("Configuring Firebase...")
        //errors for InAppMessaging for now until we implement that
        FirebaseApp.configure()
    }
    
    
    var body: some Scene {
        WindowGroup {
            Content().onOpenURL {
                url in GIDSignIn.sharedInstance.handle(url)
            }
        
        }
    }
}

struct Content: View {
    @State private var userLoggedIn = (Auth.auth().currentUser != nil)

    var body: some View {
        VStack {
            if userLoggedIn {
                NavigationStack {
                    MainScreen()
//                    LoggedInView()
                }
            } else {
                AuthScreen()
            }
        }.onAppear{
            //Firebase state change listeneer
            Auth.auth().addStateDidChangeListener{ auth, user in
                if (user != nil) {
                    userLoggedIn = true
                    silentGoogleSignIn() // New addition
                } else {
                    userLoggedIn = false
                }
            }
        }
    }
    
    private func silentGoogleSignIn() {
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if error != nil || user == nil {
                    // Handle error or sign-out state
                }
                // User is signed in with Google
                // Proceed with app flow
            }
        }
    }
}
