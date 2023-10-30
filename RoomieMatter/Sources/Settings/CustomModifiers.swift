import SwiftUI

extension View {
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 4)
    }
    func lightShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 2)
    }
}
