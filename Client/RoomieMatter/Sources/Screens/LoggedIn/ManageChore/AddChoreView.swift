

import SwiftUI

struct AddChoreView: View {
    @StateObject var viewModel: AddChoreViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(roommates: [Roommate]){
        self._viewModel = StateObject(wrappedValue: AddChoreViewModel(roommates: roommates))
    }
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.newChore.name)
                InputView(placeholder: "\(Date(timeIntervalSince1970: viewModel.newChore.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
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
                            viewModel.newChore.date = newValue.timeIntervalSince1970
                        }
                }
                InputView(placeholder: "Frequency", text: .constant(""))
                    .disabled(true)
                    .overlay(
                        HStack {
                            Spacer()
                            Picker("Frequency: ", selection: $viewModel.newChore.frequency) {
                                ForEach(Chore.Frequency.allCases, id: \.self){ freq in
                                    Text(freq.asString)
                                    
                                }
                            }
                        }
                    )
                TextEditorView(text: $viewModel.newChore.description)
                    .frame(height: 250)
                InputView(placeholder: "Add Assignees", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        HStack{
                            Spacer()
                            Button{
                                viewModel.addAssignees.toggle()
                            } label: {
                                VStack {
                                    Image(systemName: viewModel.addAssignees ? "minus" : "plus")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                        .padding(.vertical,viewModel.addAssignees ? 12 : 2)
                                        .background(
                                            Circle()
                                                .foregroundStyle(.roomieMatter)
                                        )
                                        .padding()
                                    
                                }
                            }
                        }
                    }
                if viewModel.addAssignees{
                    ForEach(viewModel.roommates){ roommate in
                        HStack {
                            RoommateStatusView(isSelf: false, roommate: roommate)
                            Button{
                                if viewModel.newChore.checkContains(roommate: roommate) {
                                    viewModel.newChore.assignedRoommates.removeAll {
                                        $0.id == roommate.id
                                    }
                                } else{
                                    viewModel.newChore.assignedRoommates.append(roommate)
                                }
                            } label: {
                                Image(systemName: viewModel.newChore.assignedRoommates.contains(where: {
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
                    viewModel.saveChore()
                    dismiss()
                }
                
                Spacer()
            }
            .padding()
            .toolbarBackground(Color.roomieMatter)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    AddChoreView(roommates: [Roommate.Example1, Roommate.Example2])
}
