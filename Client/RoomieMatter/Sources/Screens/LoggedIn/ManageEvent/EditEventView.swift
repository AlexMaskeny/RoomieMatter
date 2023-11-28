

import SwiftUI

struct EditEventView: View {
    @StateObject var viewModel: EditEventViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(roommates: [Roommate], event: Chore){
        self._viewModel = StateObject(wrappedValue: EditEventViewModel(roommates: roommates, event: event))
    }
    
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.event.name)
                InputView(placeholder: "\(Date(timeIntervalSince1970: viewModel.event.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        Button{
                            viewModel.showingDatePicker.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "calendar")
                                    .padding(.trailing)
                                    .font(.title)
                            }
                        }
                    }
                if viewModel.showingDatePicker{
                    DatePicker("Date Picker", selection: $viewModel.date, in: Date.now...)
                        .datePickerStyle(.graphical)
                        .onChange(of: viewModel.date) { oldValue, newValue in
                            viewModel.event.date = newValue.timeIntervalSince1970
                        }
                }
                InputView(placeholder: "Frequency", text: .constant(""))
                    .disabled(true)
                    .overlay(
                        HStack {
                            Spacer()
                            Picker("Frequency: ", selection: $viewModel.event.frequency) {
                                ForEach(Chore.Frequency.allCases, id: \.self){ freq in
                                    Text(freq.asString)
                                    
                                }
                            }
                        }
                    )
                TextEditorView(text: $viewModel.event.description)
                    .frame(height: 250)
                
                ForEach(viewModel.roommates){ roommate in
                    HStack {
                        RoommateStatusView(isSelf: false, roommate: roommate)
                        Button{
                            if viewModel.event.checkContains(roommate: roommate) {
                                viewModel.event.assignedRoommates.removeAll {
                                    $0.id == roommate.id
                                }
                            } else{
                                viewModel.event.assignedRoommates.append(roommate)
                            }
                        } label: {
                            Image(systemName: viewModel.event.assignedRoommates.contains(where: {
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
    EditEventView(roommates: [Roommate.Example1, Roommate.Example2], event: Chore.Example1)
}
