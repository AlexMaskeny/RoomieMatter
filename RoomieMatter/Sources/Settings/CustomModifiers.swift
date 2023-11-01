import SwiftUI

extension View {
    //Shadow
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 4)
    }
    func lightShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 2)
    }
    
    //Font
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
    
    //Buttons
    func solidButton(backgroundColor: Color = Color.roomieMatter) -> some View {
        self
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(Style.borderRadius)
    }
    
    func outlineButton(
        backgroundColor: Color = Color.roomieMatter,
        outlineColor: Color = Color.background
    ) -> some View {
        self
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(Style.borderRadius)
            .overlay(RoundedRectangle(cornerRadius: Style.borderRadius).stroke(outlineColor, lineWidth: 4))
    }
}
