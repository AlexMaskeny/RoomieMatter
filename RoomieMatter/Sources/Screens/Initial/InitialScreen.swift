import SwiftUI

struct InitialScreen: View {
    @State private var isShowingCreateAccount = false
    @State private var isShowingLogIn = false
    
    func createAccount() {
        isShowingCreateAccount.toggle()
    }
    
    func login() {
        isShowingLogIn.toggle()
    }
    
    var body: some View {
        ZStack {
            Color.roomieMatter.ignoresSafeArea()
            VStack {
                Text("RoomieMatter")
                    .bigTitle()
                    .foregroundColor(Color.background)
                    .padding(2)

                ButtonView(text: "Create an account", 
                           type: ButtonType.solidBlank,
                           action: createAccount
                )
                LineText(text: "Or Login", action: login)
            }.padding(EdgeInsets(top: 0, leading: Style.screenPadding, bottom: 100, trailing: Style.screenPadding))
        }
        .navigationDestination(isPresented: $isShowingCreateAccount) {
            CreateAccount1()
        }
        .navigationDestination(isPresented: $isShowingLogIn) {
            LoginScreen()
        }
    }
}
