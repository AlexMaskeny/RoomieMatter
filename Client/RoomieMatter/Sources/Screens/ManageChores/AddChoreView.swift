

import SwiftUI

struct AddChoreView: View {
    @State private var newChore = Chore(id: UUID().uuidString, name: "", date: Date().timeIntervalSince1970, description: "", author: Roommate.Example1, assignedRoommates: [], frequency: .once)
    @State var date = Date.now
    @State private var showingDatePicker = false
    @State private var addAssignees = false
    var roommates = [Roommate.Example1, Roommate.Example2]
    var body: some View {
        ScrollView {
            VStack {
                InputView(placeholder: "Chore Name", text: $newChore.name)
                InputView(placeholder: "\(Date(timeIntervalSince1970: newChore.date).formatted(date: .abbreviated, time: .shortened))", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        Button{
                            showingDatePicker.toggle()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "calendar")
                                    .padding(.trailing)
                                    .font(.title)
                            }
                        }
                    }
                if showingDatePicker{
                    DatePicker("Date Picker", selection: $date, in: Date.now...)
                        .datePickerStyle(.graphical)
                        .onChange(of: date) { oldValue, newValue in
                            newChore.date = newValue.timeIntervalSince1970
                        }
                }
                InputView(placeholder: "Frequency", text: .constant(""))
                    .disabled(true)
                    .overlay(
                        HStack {
                            Spacer()
                            Picker("Frequency: ", selection: $newChore.frequency) {
                                ForEach(Chore.Frequency.allCases, id: \.self){ freq in
                                    Text(freq.asString)
                                    
                                }
                            }
                        }
                    )
                TextEditorView(placeholder: "Description", text: $newChore.description)
                    .frame(height: 250)
                InputView(placeholder: "Add Assignees", text: .constant(""))
                    .disabled(true)
                    .overlay {
                        HStack{
                            Spacer()
                            Button{
                                addAssignees.toggle()
                            } label: {
                                VStack {
                                    Image(systemName: addAssignees ? "minus" : "plus")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                        .padding(.vertical,addAssignees ? 12 : 2)
                                        .background(
                                            Circle()
                                                .foregroundStyle(.roomieMatter)
                                        )
                                        .padding()
                                    
                                }
                            }
                        }
                    }
                if addAssignees{
                    ForEach(roommates){ roommate in
                        HStack {
                            RoommateStatusView(isSelf: false, roommate: roommate)
                            Button{
                                if newChore.checkContains(roommate: roommate) {
                                    newChore.assignedRoommates.removeAll {
                                        $0.id == roommate.id
                                    }
                                } else{
                                    newChore.assignedRoommates.append(roommate)
                                }
                            } label: {
                                Image(systemName: newChore.assignedRoommates.contains(where: {
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
                TLButton(title: "Save", backgroundColor: .roomieMatter){
                    
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

#Preview {
    AddChoreView()
}
