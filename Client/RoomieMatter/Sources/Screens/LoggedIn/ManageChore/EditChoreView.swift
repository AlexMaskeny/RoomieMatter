

import SwiftUI

struct EditChoreView: View {
    @StateObject var viewModel: EditChoreViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var loggedInViewViewModel: LoggedInViewViewModel
    @Binding var delete:Bool
    
    init(loggedInViewViewModel: LoggedInViewViewModel, chore: Chore, showing: Binding<Bool>){
        self._viewModel = StateObject(wrappedValue: EditChoreViewModel(roommates: loggedInViewViewModel.roommates, chore: chore, user: loggedInViewViewModel.user))
        self._delete = showing
        self._loggedInViewViewModel = ObservedObject(wrappedValue: loggedInViewViewModel)
    }
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $viewModel.chore.name)
                InputView(placeholder: "Chore Day: \(Date(timeIntervalSince1970: viewModel.chore.date).formatted(date: .abbreviated, time: .omitted))", text: .constant(""))
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
                
                DatePicker("Start Time: ", selection: $viewModel.date, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .onChange(of: viewModel.date) { oldValue, newValue in
                        viewModel.chore.date = newValue.timeIntervalSince1970
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
                
                ForEach(viewModel.possibleAssignees){ roommate in
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
                    if loggedInViewViewModel.user.id == "1" {
                        let idx = loggedInViewViewModel.chores.firstIndex { chore in
                            chore.id == viewModel.chore.id
                        }
                        guard let idx = idx else { return }
                        loggedInViewViewModel.chores.remove(at: idx)
                    } else {
                        viewModel.deleteChore()
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
                        let idx = loggedInViewViewModel.chores.firstIndex { chore in
                            chore.id == viewModel.chore.id
                        }
                        guard let idx = idx else { return }
                        loggedInViewViewModel.chores[idx].name = viewModel.chore.name
                        loggedInViewViewModel.chores[idx].date = viewModel.date.timeIntervalSince1970
                        loggedInViewViewModel.chores[idx].description = viewModel.chore.description
                        loggedInViewViewModel.chores[idx].assignedRoommates = viewModel.chore.assignedRoommates
                    } else{
                        viewModel.saveChore()
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


