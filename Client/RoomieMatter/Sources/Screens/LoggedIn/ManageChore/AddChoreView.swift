

import SwiftUI

struct AddChoreView: View {
    @StateObject var viewModel: AddChoreViewModel
    @StateObject var loggedInViewViewModel: LoggedInViewViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(author: Roommate, roommates: [Roommate], loggedInViewViewModel: LoggedInViewViewModel){
        self._loggedInViewViewModel = StateObject(wrappedValue: loggedInViewViewModel)
        self._viewModel = StateObject(wrappedValue: AddChoreViewModel(author: author, roommates: roommates))
    }
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.name)
                InputView(placeholder: "\(viewModel.date.formatted(date: .abbreviated, time: .omitted))", text: .constant(""))
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
                DatePicker("Date Picker", selection: $viewModel.date, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                InputView(placeholder: "Frequency", text: .constant(""))
                    .disabled(true)
                    .overlay(
                        HStack {
                            Spacer()
                            Picker("Frequency: ", selection: $viewModel.frequency) {
                                ForEach(Chore.Frequency.allCases, id: \.self){ freq in
                                    Text(freq.asString)
                                    
                                }
                            }
                        }
                    )
                TextEditorView(text: $viewModel.description)
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
                                if viewModel.checkContains(roommate: roommate) {
                                    viewModel.assignedRoommates.removeAll {
                                        $0.id == roommate.id
                                    }
                                } else{
                                    viewModel.assignedRoommates.append(roommate)
                                }
                            } label: {
                                Image(systemName: viewModel.assignedRoommates.contains(where: {
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
                    loggedInViewViewModel.getChores1()
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


