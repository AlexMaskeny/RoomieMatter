

import Foundation

class EditChoreViewModel:ObservableObject{
    @Published var chore: Chore
    @Published var date = Date.now
    @Published var showingDatePicker = false
    @Published var addAssignees = false
    var roommates: [Roommate]
    
    init(roommates: [Roommate], chore: Chore){
        self.roommates = roommates
        self.chore = chore
    }
    
    func saveChore(){
        
    }
    
    func deleteChore(){
        
    }
}
