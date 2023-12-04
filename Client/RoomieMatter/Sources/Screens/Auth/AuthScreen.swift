import SwiftUI
import Firebase
import FirebaseAuth

struct AuthScreen: View {
    @State private var err: String = ""
    @State private var isLoading: Bool = false
    
    func login() {
        isLoading = true
        Task {
            do {
                try await Authentication().googleoauth()
            } catch let e {
                print(e)
                err = e.localizedDescription
            }
        }
    }
    
    func tryDemo() {
        print("Demo")
    }
    
    var body: some View {
        ZStack {
            Color.roomieMatter.ignoresSafeArea()
            VStack {
                Text("RoomieMatter")
                    .bigTitle()
                    .foregroundColor(Color.background)
                    .padding(2)
                
                Button(action: login) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(Color.textLight)
                                .scaleEffect(1.2)
                        } else {
                            Image("GoogleIcon").resizable()
                                .frame(width: Style.buttonIconSize, height: Style.buttonIconSize)
                            Text("Sign in with Google")
                                .title()
                                .foregroundColor(Color.textLight)
                        }
                    }
                    .solidButton(backgroundColor: Color.background)
                    
                }
                
                Text(err).foregroundColor(.red).caption()
                NavigationLink{
                    LoggedInView()
                } label: {
                    Text("Try demo")
                        .foregroundStyle(.white)
                    //LineText(text: "Try Demo", action: tryDemo)
                }
                
            }
            .padding(.horizontal, Style.screenPadding)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    AuthScreen()
}
