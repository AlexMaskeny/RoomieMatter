//
//  AddEventView.swift
//  RoomieMatter
//
//  Created by Lasya Mantha on 11/29/23.
//

import SwiftUI

struct AddEventView: View {
    @StateObject var viewModel: AddEventViewModel
    @StateObject var loggedInViewViewModel: LoggedInViewViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(loggedInViewViewModel: LoggedInViewViewModel){
        self._loggedInViewViewModel = StateObject(wrappedValue: loggedInViewViewModel)
        self._viewModel = StateObject(wrappedValue: AddEventViewModel(author: loggedInViewViewModel.user, roommates: loggedInViewViewModel.roommates))
    }
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Event Name", text: $viewModel.name)
                InputView(placeholder: "Start Time: \(viewModel.date.formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        HStack {
                            Spacer()
                            Image(systemName: "calendar")
                                .padding(.trailing)
                                .font(.title)
                                .foregroundStyle(.roomieMatter)
                        }
                    }
                DatePicker("Event Start: ", selection: $viewModel.date, in: Date.now...)
                    .datePickerStyle(.graphical)
                InputView(placeholder: "End Time: \(viewModel.dateEnd.formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        HStack {
                            Spacer()
                            Image(systemName: "calendar")
                                .padding(.trailing)
                                .font(.title)
                                .foregroundStyle(.roomieMatter)
                        }
                    }
                DatePicker("Event End: ", selection: $viewModel.dateEnd, in: Date.now...)
                    .datePickerStyle(.graphical)
                
                TextEditorView(placeholder: "Description", text: $viewModel.description)
                    .frame(height: 250)
                InputView(placeholder: "Add Guests", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        HStack{
                            Spacer()
                            Button{
                                viewModel.addGuests.toggle()
                            } label: {
                                VStack {
                                    Image(systemName: viewModel.addGuests ? "minus" : "plus")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                        .padding(.vertical,viewModel.addGuests ? 12 : 2)
                                        .background(
                                            Circle()
                                                .foregroundStyle(.roomieMatter)
                                        )
                                        .padding()
                                    
                                }
                            }
                        }
                    }
                if viewModel.addGuests{
                    ForEach(viewModel.possibleGuests){ roommate in
                        HStack {
                            RoommateStatusView(isSelf: false, roommate: roommate)
                            Button{
                                if viewModel.checkContains(roommate: roommate) {
                                    viewModel.guests.removeAll {
                                        $0.id == roommate.id
                                    }
                                } else{
                                    viewModel.guests.append(roommate)
                                }
                            } label: {
                                Image(systemName: viewModel.guests.contains(where: {
                                    $0.id == roommate.id
                                }) ? "trash" : "plus")
                                .padding()
                                .font(.title)
                                .foregroundStyle(.black)
                            }
                        }
                        Divider()
                    }
                }
                CustomButton(title: "Save", backgroundColor: .roomieMatter){
                    if loggedInViewViewModel.user.id == "1"{
                        let newEvent = Event(id: UUID().uuidString, name: viewModel.name, date: viewModel.date.timeIntervalSince1970, dateEnd: viewModel.dateEnd.timeIntervalSince1970, description: viewModel.description, author: viewModel.author, Guests: viewModel.guests)
                        loggedInViewViewModel.events.append(newEvent)
                    } else{
                        viewModel.saveEvent()
                    }
                    dismiss()
                }
                
                Spacer()
            }
            .padding()
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    struct TextEditorView: View {
        var placeholder: String
        @Binding var text: String
        var color: Color = Color.container
        
        var body: some View {
            TextEditor(text: $text)
                .padding()
                .background(color)
                .scrollContentBackground(.hidden)
                .frame(minWidth: 0, maxWidth: .infinity)
                .cornerRadius(Style.borderRadius)
        }
    }
    struct TLButton: View {
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
}



