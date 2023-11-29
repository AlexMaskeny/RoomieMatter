
import Foundation


class AddChoreViewModel:ObservableObject{
    @Published var newChore = Chore(id: UUID().uuidString, name: "", date: Date().timeIntervalSince1970, description: "", author: Roommate.Example1, assignedRoommates: [], frequency: .once)
    @Published var date = Date.now
    @Published var showingDatePicker = false
    @Published var addAssignees = false
    var roommates: [Roommate]
    
    init(roommates: [Roommate]){
        self.roommates = roommates
    }
    
    func saveChore(){
        
    }
}
