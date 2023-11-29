

import Foundation

class EditEventViewModel:ObservableObject{
    @Published var event: Event
    @Published var date = Date.now
    @Published var showingDatePicker = false
    @Published var addAssignees = false
    var roommates: [Roommate]
    
    init(roommates: [Roommate], event: Event){
        self.roommates = roommates
        self.event = event
    }
    
    func saveEvent(){
        
    }
    
    func deleteEvent(){
        
    }
}
