import SwiftUI

struct LoginScreen: View {
    @State private var isShowingCreateAccount1 = false
    
    func login() {
        print("Login")
    }

    func createAccount() {
        isShowingCreateAccount1 = true
        print("Navigate to createAccount1")
    }
    
    var body: some View {
        ZStack {
            Color.roomieMatter.ignoresSafeArea()
            VStack {
                Spacer()
                Text("RoomieMatter")
                    .bigTitle()
                    .foregroundColor(Color.background)
                    .padding(2)

                ButtonView(text: "Login",
                           type: ButtonType.outlineBlank,
                           action: login
                )
                .padding(.bottom, 100)
                Spacer()
                LineText(text: "Or Sign Up", action: createAccount).padding(.horizontal, 10)
                
            }
            .padding(.horizontal, Style.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        .navigationDestination(isPresented: $isShowingCreateAccount1) {
            CreateAccount1()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoginScreen()
}
