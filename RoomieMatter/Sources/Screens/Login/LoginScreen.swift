import SwiftUI

struct LoginScreen: View {
    
    func login() {
        print("Login")
    }

    func createAccount() {
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
                Spacer()
                LineText(text: "Or Sign Up", action: createAccount)
            }.padding(EdgeInsets(top: 0, leading: Style.screenPadding, bottom: 100, trailing: Style.screenPadding))
        }
    }
}
