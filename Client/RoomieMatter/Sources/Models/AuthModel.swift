import Firebase
import GoogleSignIn
import FirebaseAuth

//Reference: https://medium.com/@matteocuzzolin/google-sign-in-with-firebase-in-swiftui-app-c8dc7b7ed4f9

@MainActor
struct Authentication {
    func googleoauth() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("no firebase clientID found")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let rootViewController =  scene?.windows.first?.rootViewController
        else {
            fatalError("no root view controller")
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: "Add google calendar", additionalScopes: ["https://www.googleapis.com/auth/calendar"])
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw "Unexpected error occurred, please retry"
        }
        
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
        try await Auth.auth().signIn(with: credential)
    }
    func logout() async throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }
}

extension String: Error {}
