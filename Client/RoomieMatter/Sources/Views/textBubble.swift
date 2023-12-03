import SwiftUI

// Define an enum for the position of the text bubble
enum BubblePosition {
    case left
    case right
}

// Define a struct for the TextBubble view
struct TextBubble: View {
    let chat: Chat
    let position: BubblePosition

    // Formatter to display the timestamp
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack {
            if position == .right {
                Spacer()
            }

            VStack(alignment: position == .left ? .leading : .trailing) {
                Text(chat.username)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)

                Text(dateFormatter.string(from: chat.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)

                Text(chat.message)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(position == .left ? Color.blue : Color.green)
                    .cornerRadius(15)
            }
            .frame(maxWidth: .infinity, alignment: position == .left ? .leading : .trailing)

            if position == .left {
                Spacer()
            }
        }
        .padding(position == .left ? .leading : .trailing, 20)
    }
}

// Preview for SwiftUI Canvas
//struct TextBubble_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            TextBubble(
//                chat: Chat(username: "Alexander David Maskeny", message: "Hi David", timestamp: Date()),
//                position: .left
//            )
//            TextBubble(
//                chat: Chat(username: "David Wang", message: "Hi Alex", timestamp: Date()),
//                position: .right
//            )
//        }
//        .padding()
//    }
//}
