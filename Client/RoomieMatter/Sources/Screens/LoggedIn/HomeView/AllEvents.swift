import SwiftUI

struct AllEvents: View {
    var events: [Event]
    
    var body: some View {
        List(events) { event in
            SingleEventView(event: event)
        }
    }
}

struct SingleEventView: View {
    var event: Event
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.name)
                .font(.title2)
                .bold()
                .foregroundStyle(.roomieMatter)
            if Calendar.current.isDateInToday(Date(timeIntervalSince1970: event.date)){
                Text("Today")
                    .font(.subheadline)
            } else if Calendar.current.isDateInTomorrow(Date(timeIntervalSince1970: event.date)) {
                Text("Tomorrow")
                    .font(.subheadline)
            } else{
                Text(Date(timeIntervalSince1970: event.date), format: .dateTime.weekday())
                    .font(.subheadline)
            }
            
            Spacer()
                .frame(height: 10)
            Text(event.description)
            
            Spacer()
                .frame(height: 20)
            
            HStack {
                ForEach(event.Guests){roommate in
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
    AllEvents(events: [Event.Example1, Event.Example2])
}
