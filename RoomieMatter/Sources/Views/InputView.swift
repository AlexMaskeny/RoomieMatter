import SwiftUI

struct InputView: View {
    var placeholder: String
    @Binding var text: String
    var color: Color = Color("Container")
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(color)
            .cornerRadius(Style.borderRadius)
            .padding([.leading, .trailing], 15)
    }
}
