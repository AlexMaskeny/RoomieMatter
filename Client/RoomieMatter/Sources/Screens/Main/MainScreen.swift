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
            getChore(instanceId: "s8um45gtu9dn4f4v1r80h7h69k_20231202")
        } label: {
            Text("Get chore")
        }
        
        Button {
            getChores()
        } label: {
            Text("Get chores")
        }
        
        Button {
            print(addChore(name: "name", date: Date(), description: "description", assignedRoommates: "roommate"))
        } label: {
            Text("Add chore")
        }
        
        Button {
            completeChore(instanceId: "fpkh4gu4f80j3noorhassgg6g4_20231202")
        } label: {
            Text("Complete chore")
        }
        
        Button {
            deleteChore(instanceId: "sgu87r22jp0blbemulna09mg2s_20231202")
        } label: {
            Text("Delete chore")
        }
        
        Button {
            getEvents()
        } label: {
            Text("Get events")
        }
        
        Button {
            addEvent()
        } label: {
            Text("Add event")
        }
        
        Button {
            deleteEvent()
        } label: {
            Text("Delete event")
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
