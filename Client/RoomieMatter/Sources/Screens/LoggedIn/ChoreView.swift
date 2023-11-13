

import SwiftUI

struct ChoreView: View {
    var chore: Chore
    var body: some View {
        VStack(alignment: .leading){
            Text(chore.name)
                .font(.headline)
            if Calendar.current.isDateInToday(Date(timeIntervalSince1970: chore.date)){
                Text("Today")
                    .font(.subheadline)
            } else if Calendar.current.isDateInTomorrow(Date(timeIntervalSince1970: chore.date)) {
                Text("Tomorrow")
                    .font(.subheadline)
            } else{
                Text(Date(timeIntervalSince1970: chore.date), format: .dateTime.weekday())
                    .font(.subheadline)
            }
            
            
            HStack {
                ForEach(chore.assignedRoommates){roommate in
                    if let image = roommate.image{
                        image
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .scaledToFill()
                            .overlay(
                                Circle()
                                    .stroke()
                            )
                    } else {
                        Image(systemName: "person.fill")
                            .font(.headline)
                            .padding(10)
                            .background(
                                Circle()
                                    .foregroundStyle(.white)
                                    .overlay(
                                        Circle()
                                            .stroke()
                                    )
                            )
                    }
                    
                }
            }
            
        }
        .padding()
        .background(Color(white: 0.9))
        .cornerRadius(10)
    }
}

#Preview {
    ChoreView(chore: Chore.Example1)
}
