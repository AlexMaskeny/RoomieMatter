

import SwiftUI

struct RoommateStatusView: View {
    let isSelf: Bool
    let roommate: Roommate
    var body: some View {
        HStack{
            Group{
                if let image = roommate.image{
                    image
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .scaledToFill()
                        .overlay(
                            Circle()
                                .stroke()
                        )
                    
                } else{
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
                }
            }
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
                    Text(roommate.displayName)
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
