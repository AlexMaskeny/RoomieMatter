import SwiftUI

struct InputView: View {
    var placeholder: String
    @Binding var text: String
    var color: Color = Color.container
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(color)
            .frame(minWidth: 0, maxWidth: .infinity)
            .cornerRadius(Style.borderRadius)
    }
}
