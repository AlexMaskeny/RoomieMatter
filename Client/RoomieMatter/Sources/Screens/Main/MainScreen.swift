import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import GoogleSignIn

let db = Firestore.firestore()

//This screen is essentially a placeholder.
//Feel free to add code to make this another screen

//At this point the user is logged in...

//Reference for FireStore: https://devbrite.io/firestore-swift-ios
//@David ^^ This has info on implementing listening for the chat view

struct MainScreen: View {
    @State private var err : String = ""
    
    var body: some View {
        HStack {
            Image(systemName: "hand.wave.fill")
            Text(
                "Hello " +
                (Auth.auth().currentUser!.displayName ?? "Username not found")
            )
        }
        
        Button {
            getChores()
        } label: {
            Text("Test get chores")
        }
        
        Button {
            db.collection("test").addDocument(data: [
                "title": "Test"
            ])
        } label: {
            Text("Test add document")
        }
        
        Button {
            db.collection("users").getDocuments {(snapshot, error) in
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        print(document.data())
                    }
                }
            }
        } label: {
            Text("Print all users")
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
        }.buttonStyle(.borderedProminent)
        
        NavigationLink("Chat", destination: ChatScreen())
        //NavigationLink("Home", destination: HomeView())
        
        Text(err).foregroundColor(.red).font(.caption)
    }
}

#Preview {
    MainScreen()
}
