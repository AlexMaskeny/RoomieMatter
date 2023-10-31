import SwiftUI

struct LineText: View {
    var text: String
    var action: () -> Void = {}
    
    @ViewBuilder
    func Line() -> some View {
        Rectangle().fill(Color.background).frame(height: 2)
    }
    
    var body: some View {
        HStack {
            Line()
            Spacer()
            Button(action: action) {
                Text(text)
                    .font(.system(size: Style.fontSize.subTitle))
                    .foregroundColor(Color.background)
            }.padding(4)
            Spacer()
            Line()
            
        }
    }
}
