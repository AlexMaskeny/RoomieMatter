import SwiftUI

extension View {
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 4)
    }
    func lightShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 2)
    }
    func bigTitle() -> some View {
        self.font(.system(size: Style.fontSize.bigTitle, weight: Font.Weight.heavy))
    }
    func title() -> some View {
        self.font(.system(size: Style.fontSize.title, weight: Font.Weight.bold))
    }
    func subTitle() -> some View {
        self.font(.system(size: Style.fontSize.subTitle))
    }
    func caption() -> some View {
        self.font(.system(size: Style.fontSize.caption))
    }
}
