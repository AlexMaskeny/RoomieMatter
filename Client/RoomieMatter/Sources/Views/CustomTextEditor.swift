import SwiftUI

struct TextEditorView: View {
    @Binding var text: String
    var color: Color = Color.container
    
    var body: some View {
        TextEditor(text: $text)
            .padding()
            .background(color)
            .scrollContentBackground(.hidden)
            .frame(minWidth: 0, maxWidth: .infinity)
            .cornerRadius(Style.borderRadius)
    }
}

#Preview {
    TextEditorView(text: .constant("Placeholder"), color: .roomieMatter)
}
