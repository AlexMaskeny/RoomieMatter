import SwiftUI

/*This is just me playing around. This won't even have an input */
struct InitialScreen: View {
    @State private var test = ""
    
    var body: some View {
        ZStack {
            Color("Primary").ignoresSafeArea()
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                InputView(placeholder: "Email", text: $test, color: Color("Background"))
            }
            .padding()
        }
    }
}

struct InitialScreen_Previews: PreviewProvider {
    static var previews: some View {
        InitialScreen()
    }
}
