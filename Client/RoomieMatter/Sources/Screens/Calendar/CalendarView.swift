import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var events: [Event]
    @State private var fetchedEvents: [Event] = []
    var currentEvents: [Event] {
        events.filter { event in
            Calendar.current.isDate(Date(timeIntervalSince1970: event.date), inSameDayAs: selectedDate)
        }
    }
    private var authViewModel = AuthenticationViewModel.shared
    
    init(events: [Event]) {
        _events = State(initialValue: events)
        _fetchedEvents = State(initialValue: events)
    }

    var body: some View {
        ScrollView {
            VStack {
                // DatePicker
                DatePicker(
                    "Select a date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .overlay(Divider().background(Color.black), alignment: .bottom)
                .padding()
                
                ForEach(currentEvents){event in
                    EventCardView(event: event)
                }
                
                

                // Event cards
                
                // Fetched Event cards
                
                
                // Add Event Button
                

                
            }
            .padding()
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
                    // Fetch events when the view appears
                    //fetchEvents(for: selectedDate)
        }

    }
    
    // Function to fetch events from Firestore
    private func fetchEvents(for date: Date) {
        let db = Firestore.firestore()
        let eventsCollection = db.collection("events")  // Replace with your Firestore collection name

        // Convert the selectedDate to a timestamp for comparison
        let selectedDateTimestamp = Timestamp(date: date)

        // Query events for the selected date
        eventsCollection
            .whereField("date", isEqualTo: selectedDateTimestamp)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching events: \(error.localizedDescription)")
                } else {
                    // Clear existing events using wrappedValue
                    _events.wrappedValue = []

                    // Parse the fetched events manually
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        do {
                            let id = document.documentID
                            let name = data["name"] as? String ?? ""
                            let date = data["date"] as? Double ?? 0
                            let description = data["description"] as? String ?? ""
                            
                            // Extract Roommate data
                            let roommateData = data["author"] as? [String: Any] ?? [:]
                            let roommate = self.parseRoommateData(roommateData: roommateData)
                            
                            // Extract Guests data
                            var guests: [Roommate] = []
                            if let guestsData = data["Guests"] as? [[String: Any]] {
                                for guestData in guestsData {
                                    let guest = self.parseRoommateData(roommateData: guestData)
                                    guests.append(guest)
                                }
                            }
                            
                            let event = Event(id: id, name: name, date: date, dateEnd: date + 3600, description: description, author: roommate, Guests: guests)
                            
                            // Append the event to the @State variable's content
                            fetchedEvents.append(event)
                        } catch {
                            print("Error creating event: \(error.localizedDescription)")
                        }
                    }
                }
            }
    }

    private func parseRoommateData(roommateData: [String: Any]) -> Roommate {
        let id = roommateData["id"] as? String ?? ""
        let displayName = roommateData["displayName"] as? String ?? ""
        let photoURLString = roommateData["photoURL"] as? String
        let photoURL = photoURLString != nil ? URL(string: photoURLString!) : nil
        let statusString = roommateData["status"] as? String ?? "notHome"
        let status = interpretString(status: statusString)
        
        return Roommate(id: id, displayName: displayName, photoURL: photoURL, status: status)
    }

    struct AddEventButton: View {
        let title: String
        let backgroundColor: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                ZStack {
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
    
    struct EventCardView: View {
        var event: Event
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(event.name)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.blue)

                Text(Date(timeIntervalSince1970: event.date), format: .dateTime)
                    .font(.subheadline)
            
                
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
}

#Preview {
    CalendarView(events: [Event.Example1])
}
