

import SwiftUI

struct RoommateStatusView: View {
    let isSelf: Bool
    let roommate: Roommate
    var body: some View {
        HStack{
            Image(systemName: "person.fill")
                .font(.title)
                .padding()
                .background(
                    Circle()
                        .foregroundStyle(.gray)
                        .overlay(
                        Circle()
                            .stroke()
                        )
                )
                .overlay(alignment: .bottomTrailing){
                    Circle()
                        .frame(width: 15)
                        .foregroundStyle(roommate.status.color)
                        .overlay(
                        Circle()
                            .stroke()
                        )
                }
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8){
                HStack {
                    Text(roommate.name)
                        .font(.headline)
                    .bold()
                    if isSelf {
                        Text("(you)")
                            .foregroundStyle(.gray)
                    }
                }
                Text(roommate.status.status)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
    }
}

#Preview {
    RoommateStatusView(isSelf: true, roommate: Roommate.Example1)
}
