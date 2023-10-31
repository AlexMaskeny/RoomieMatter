import SwiftUI

enum ButtonType: CaseIterable {
    case solidBlank
    case solidColor
    case outlineBlank
}

struct ButtonView: View {
    var text: String
    var type: ButtonType = ButtonType.solidColor
    var action: () -> Void = {}
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
                .title()
        }
        .lightShadow()
    }
    
    private var buttonBackground: some View {
        switch type {
        case .solidBlank:
            return backgroundColor ?? Color.background
        case .solidColor:
            return backgroundColor ?? Color.roomieMatter
        case .outlineBlank:
            return backgroundColor ?? Color.roomieMatter
        }
    }
    
    private var buttonForeground: Color {
        switch type {
        case .solidBlank:
            return textColor ?? Color.textLight
        case .solidColor:
            return textColor ?? Color.background
        case .outlineBlank:
            return textColor ?? Color.background
        }
    }
    
    private var buttonOverlay: some View {
        switch type {
        case .outlineBlank:
            return AnyView(RoundedRectangle(cornerRadius: Style.borderRadius).stroke(Color.background, lineWidth: 4))
        default:
            return AnyView(EmptyView())
        }
    }
}
