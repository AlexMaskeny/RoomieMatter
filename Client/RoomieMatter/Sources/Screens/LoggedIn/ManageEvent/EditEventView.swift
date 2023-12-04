

import SwiftUI

struct EditEventView: View {
    @StateObject var viewModel: EditEventViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject var loggedInViewViewModel: LoggedInViewViewModel
    @Binding var delete:Bool
    
    init(loggedInViewViewModel: LoggedInViewViewModel, roommates: [Roommate], event: Event, showing: Binding<Bool>){
        self._viewModel = StateObject(wrappedValue: EditEventViewModel(roommates: roommates, event: event, user: loggedInViewViewModel.user))
        self._delete = showing
        self._loggedInViewViewModel = StateObject(wrappedValue: loggedInViewViewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.event.name)
                InputView(placeholder: "Event Start: \(Date(timeIntervalSince1970: viewModel.event.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
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
                
                DatePicker("Event Start: ", selection: $viewModel.dateStart, in: Date.now...)
                    .datePickerStyle(.graphical)
                InputView(placeholder: "Event End: \(Date(timeIntervalSince1970: viewModel.event.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
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
                
                
                TextEditorView(text: $viewModel.event.description)
                    .frame(height: 250)
                
                ForEach(viewModel.possibleAssignees){ roommate in
                    HStack {
                        RoommateStatusView(isSelf: false, roommate: roommate)
                        Button{
                            if viewModel.event.checkContains(roommate: roommate) {
                                viewModel.event.Guests.removeAll {
                                    $0.id == roommate.id
                                }
                            } else{
                                viewModel.event.Guests.append(roommate)
                            }
                        } label: {
                            Image(systemName: viewModel.event.Guests.contains(where: {
                                $0.id == roommate.id
                            }) ? "trash" : "plus")
                            .padding()
                            .font(.title)
                            .foregroundStyle(.black)
                        }
                    }
                    Divider()
                }
                
                
                
                CustomButton(title: "Delete", backgroundColor: .red){
                    if loggedInViewViewModel.user.id == "1" {
                        let idx = loggedInViewViewModel.events.firstIndex { event in
                            event.id == viewModel.event.id
                        }
                        guard let idx = idx else { return }
                        loggedInViewViewModel.events.remove(at: idx)
                    } else {
                        viewModel.deleteEvent()
                    }
                    
                    delete = false
                    dismiss()
                }
                
                Spacer()
            }
            .padding()
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                Button{
                    if loggedInViewViewModel.user.id == "1" {
                        let idx = loggedInViewViewModel.events.firstIndex { event in
                            event.id == viewModel.event.id
                        }
                        guard let idx = idx else { return }
                        
                        loggedInViewViewModel.events[idx].name = viewModel.event.name
                        loggedInViewViewModel.events[idx].date = viewModel.dateStart.timeIntervalSince1970
                        loggedInViewViewModel.events[idx].dateEnd = viewModel.dateEnd.timeIntervalSince1970
                        loggedInViewViewModel.events[idx].description = viewModel.event.description
                        loggedInViewViewModel.events[idx].Guests = viewModel.event.Guests
                    } else {
                        viewModel.saveEvent()
                        delete = false
                    }
                    
                    dismiss()
                } label:{
                    Text("Save")
                        .foregroundStyle(.white)
                }
            }
        }
    }
}


