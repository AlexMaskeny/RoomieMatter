//
//  EventInfo.swift
//  RoomieMatter
//
//  Created by Lasya Mantha on 11/29/23.
//

import SwiftUI

struct EventInfo: View {
    var event: Event
    var roommates: [Roommate]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var loggedInViewViewModel: LoggedInViewViewModel
    @State private var showing = true

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text(event.name)
                                .font(.title)
                                .bold()
                                .foregroundStyle(.roomieMatter)

                            Group {
                                if Calendar.current.isDateInToday(Date(timeIntervalSince1970: event.date)) {
                                    Text("Today")
                                        .font(.subheadline)
                                        
                                } else if Calendar.current.isDateInTomorrow(Date(timeIntervalSince1970: event.date)) {
                                    Text("Tomorrow")
                                        .font(.subheadline)
                                        
                                } else {
                                    Text(Date(timeIntervalSince1970: event.date), format: .dateTime.weekday())
                                        .font(.subheadline)
                                        
                                }
                                Spacer()
                                    .frame(height: 20)
                                Text(event.description)
                                    
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
                        .padding(.horizontal)


                        HStack {
                            Group {
                                if let image = event.author.image {
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
                            .overlay(alignment: .bottomTrailing) {
                                Circle()
                                    .frame(width: 15)
                                    .foregroundStyle(event.author.status.color)
                            }

                            VStack(alignment: .leading) {
                                Text("Created by:")
                                    .multilineTextAlignment(.leading)
                                Text(event.author.displayName)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
                        .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("Assignees:")
                    ForEach(event.Guests) { roommate in
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
                                                .foregroundStyle(.gray.opacity(0.3))
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
                                }
                                Text(roommate.status.status)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .onChange(of: showing, { oldValue, newValue in
                if newValue == false {
                    dismiss()
                }
            })
            .toolbar{
                NavigationLink{
                    EditEventView(loggedInViewViewModel: loggedInViewViewModel, roommates: roommates, event: event, showing: $showing)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}



