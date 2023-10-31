import SwiftUI

struct AuthScreen: View {
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

                LineText(text: "Try Demo", action: tryDemo)
            }
            .padding(.horizontal, Style.screenPadding)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    AuthScreen()
}
