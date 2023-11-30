import SwiftUI

struct AllChores: View {
    var chores: [Chore]
    
    var body: some View {
        List(chores) { chore in
            SingleChoreView(chore: chore)
        }
    }
}

struct SingleChoreView: View {
    var chore: Chore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(chore.name)
                .font(.title2)
                .bold()
                .foregroundStyle(.roomieMatter)
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
            
            Spacer()
                .frame(height: 10)
            Text(chore.description)
            
            Spacer()
                .frame(height: 20)
            
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
            
            Divider()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
    }
}

#Preview {
    AllChores(chores: [Chore.Example1, Chore.Example2])
}
