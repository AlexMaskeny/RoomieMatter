

import Foundation

class ChoreViewViewModel: ObservableObject{
    var chore: Chore
    
    var dateText: String{
        if Calendar.current.isDateInToday(Date(timeIntervalSince1970: chore.date)){
            return "Today"
        } else if Calendar.current.isDateInTomorrow(Date(timeIntervalSince1970: chore.date)) {
            return "Tomorrow"
        } else {
            let date = Date(timeIntervalSince1970: chore.date)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            
            return date.formatted(Date.FormatStyle().weekday(.wide)) + ", " + formatter.string(from: date)
        }
    }
    
    init(chore: Chore) {
        self.chore = chore
    }
}
