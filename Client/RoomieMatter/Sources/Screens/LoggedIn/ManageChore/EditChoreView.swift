

import SwiftUI

struct EditChoreView: View {
    @StateObject var viewModel: EditChoreViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var delete:Bool
    
    init(roommates: [Roommate], chore: Chore, showing: Binding<Bool>){
        self._viewModel = StateObject(wrappedValue: EditChoreViewModel(roommates: roommates, chore: chore))
        self._delete = showing
    }
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.chore.name)
                InputView(placeholder: "\(Date(timeIntervalSince1970: viewModel.chore.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
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
                            viewModel.chore.date = newValue.timeIntervalSince1970
                        }
                }
                InputView(placeholder: "Frequency", text: .constant(""))
                    .disabled(true)
                    .overlay(
                        HStack {
                            Spacer()
                            Picker("Frequency: ", selection: $viewModel.chore.frequency) {
                                ForEach(Chore.Frequency.allCases, id: \.self){ freq in
                                    Text(freq.asString)
                                    
                                }
                            }
                        }
                    )
                TextEditorView(text: $viewModel.chore.description)
                    .frame(height: 250)
                
                ForEach(viewModel.roommates){ roommate in
                    HStack {
                        RoommateStatusView(isSelf: false, roommate: roommate)
                        Button{
                            if viewModel.chore.checkContains(roommate: roommate) {
                                viewModel.chore.assignedRoommates.removeAll {
                                    $0.id == roommate.id
                                }
                            } else{
                                viewModel.chore.assignedRoommates.append(roommate)
                            }
                        } label: {
                            Image(systemName: viewModel.chore.assignedRoommates.contains(where: {
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
                    viewModel.deleteChore()
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
                    viewModel.saveChore()
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
    EditChoreView(roommates: [Roommate.Example1, Roommate.Example2], chore: Chore.Example1, showing: .constant(true))
}
