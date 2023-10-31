import SwiftUI

struct InitialScreen: View {
    func createAccount() {
        print("Navigate to createAccount1")
    }
    
    func login() {
        print("Navigate to login")
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
    }
}
