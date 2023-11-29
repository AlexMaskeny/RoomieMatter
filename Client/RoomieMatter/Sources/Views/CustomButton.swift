import SwiftUI

struct CustomButton: View {
    let title:String
    let backgroundColor:Color
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(backgroundColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .bold()
                    .padding(.vertical, 10)
            }
        }
    }
}

#Preview {
    CustomButton(title: "Test", backgroundColor: .roomieMatter) { }
}
