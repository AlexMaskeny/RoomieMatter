import SwiftUI

enum ButtonType: CaseIterable {
    case solidBlank
    case solidColor
    case outlineBlank
}

struct ButtonView: View {
    var text: String
    var type: ButtonType = ButtonType.solidColor
    var action: () -> Void
    var textColor: Color? = nil
    var backgroundColor: Color? = nil
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(buttonBackground)
                .foregroundColor(buttonForeground)
                .overlay(buttonOverlay)
                .cornerRadius(Style.borderRadius)
                .bold()
                .font(.system(size: Style.fontSize.title))
        }
        .lightShadow()
    }
    
    private var buttonBackground: some View {
        switch type {
        case .solidBlank:
            return backgroundColor ?? Color("Background")
        case .solidColor:
            return backgroundColor ?? Color("Primary")
        case .outlineBlank:
            return backgroundColor ?? Color("Primary")
        }
    }
    
    private var buttonForeground: Color {
        switch type {
        case .solidBlank:
            return textColor ?? Color("TextLight")
        case .solidColor:
            return textColor ?? Color("Background")
        case .outlineBlank:
            return textColor ?? Color("Background")
        }
    }
    
    private var buttonOverlay: some View {
        switch type {
        case .outlineBlank:
            return AnyView(RoundedRectangle(cornerRadius: Style.borderRadius).stroke(Color("Background"), lineWidth: 4))
        default:
            return AnyView(EmptyView())
        }
    }
}
