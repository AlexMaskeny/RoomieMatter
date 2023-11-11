import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

let db = Firestore.firestore()

//This screen is essentially a placeholder.
//Feel free to add code to make this another screen

//At this point the user is logged in...

//Reference for FireStore: https://devbrite.io/firestore-swift-ios
//@David ^^ This has info on implementing listening for the chat view

struct MainScreen: View {
    @State private var err : String = ""
    
    private let store = ChoreStore.shared
    
    var body: some View {
        HStack {
            Image(systemName: "hand.wave.fill")
            Text(
                "Hello " +
                (Auth.auth().currentUser!.displayName ?? "Username not found")
            )
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
        
        Button {
            Functions.functions().httpsCallable("sendChat").call(["text":"test"]) { result, error in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        print("Error: Code: \(String(describing: code)), Message: \(message), Details: \(String(describing: details))")
                    }
                    print("Error: \(error.localizedDescription)")
                    return
                }

                // If the function succeeded, process the result
                if let data = result?.data as? [String: Any], let resultText = data["message"] as? String {
                    print(resultText)
                }
                

            }
            
        } label: {
            Text("Test Functions")
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

        Text(err).foregroundColor(.red).font(.caption)
        
//      Placeholder Chore Tracking Code
        Text("Chore Tracking")
        
        List(store.chores.indices, id: \.self) {
            ChoreList(chore: store.chores[$0])
                .listRowSeparator(.hidden)
                .listRowBackground(Color(($0 % 2 == 0) ? .systemGray5 : .systemGray6))
        }
//        TODO: add properties, e.g. refreshable, navigationDestination
    }
}

#Preview {
    MainScreen()
}
