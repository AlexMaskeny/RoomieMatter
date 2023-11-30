//
//  CalendarView.swift
//  RoomieMatter
//
//  Created by Anish Sundaram on 11/27/23.
//
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var events: [Event]
    private var authViewModel = AuthenticationViewModel()
    
    init(events: [Event] = []) {
        _events = State(initialValue: events)
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
                
                

                // Event cards
                VStack {
                    ForEach(events) { event in
                        EventCardView(event: event)
                    }
                }
                
                // Add Event Button
                AddEventButton(title: "Add Event", backgroundColor: .roomieMatter) {
                    // add event view
                    print("Selected Date: \(selectedDate)")
                    print(events)
                }

                Spacer()
            }
            .padding()
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
                    // Fetch events when the view appears
                    fetchEvents(for: selectedDate)
        }

    }
    
    // Function to fetch events from Firestore
    private func fetchEvents(for date: Date) {
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
    CalendarView(events: [Event.Example1, Event.Example2])
}
