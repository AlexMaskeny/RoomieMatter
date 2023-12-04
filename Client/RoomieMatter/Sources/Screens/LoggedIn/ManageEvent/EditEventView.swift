

import SwiftUI

struct EditEventView: View {
    @StateObject var viewModel: EditEventViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var delete:Bool
    
    init(roommates: [Roommate], event: Event, showing: Binding<Bool>){
        self._viewModel = StateObject(wrappedValue: EditEventViewModel(roommates: roommates, event: event))
        self._delete = showing
    }
    
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.event.name)
                InputView(placeholder: "\(Date(timeIntervalSince1970: viewModel.event.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        Button{
                            //viewModel.showingDatePicker.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "calendar")
                                    .padding(.trailing)
                                    .font(.title)
                            }
                        }
                    }
                
                DatePicker("Date Picker", selection: $viewModel.dateStart, in: Date.now...)
                    .datePickerStyle(.graphical)
                DatePicker("Date Picker", selection: $viewModel.dateEnd, in: Date.now...)
                    .datePickerStyle(.graphical)
                
                
                TextEditorView(text: $viewModel.event.description)
                    .frame(height: 250)
                
                ForEach(viewModel.roommates){ roommate in
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
                    viewModel.deleteEvent()
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
                    viewModel.saveEvent()
                    delete = false
                    dismiss()
                } label:{
                    Text("Save")
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    EditEventView(roommates: [Roommate.Example1, Roommate.Example2], event: Event.Example1, showing: .constant(true))
}
