

import Foundation

class EditEventViewModel:ObservableObject{
    @Published var event: Chore
    @Published var date = Date.now
    @Published var showingDatePicker = false
    @Published var addAssignees = false
    var roommates: [Roommate]
    
    init(roommates: [Roommate], event: Chore){
        self.roommates = roommates
        self.event = event
    }
    
    func saveEvent(){
        
    }
    
    func deleteEvent(){
        
    }
}
