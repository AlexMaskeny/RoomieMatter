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
    @State private var userInRoom = false
    @State private var isLoading = true
    let authViewModel = AuthenticationViewModel.shared
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            }
            else {
                if userLoggedIn {
                    if userInRoom {
                        NavigationStack {
                            LoggedInView()
                        }
                    } else {
                        NavigationStack {
                            RoomHome()
                        }
                    }
                } else {
                    AuthScreen()
                }
            }
        }.onAppear{
            //Firebase state change listeneer
            Auth.auth().addStateDidChangeListener{ auth, user in
                if let _ = user {
                    userLoggedIn = true
                    silentGoogleSignIn()
                    authViewModel.fetchRoom(){
                        userInRoom = authViewModel.room_id != nil
                        isLoading = false
                    }
                } else {
                    userLoggedIn = false
                    userInRoom = false
                    isLoading = false
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
