

import Foundation

class EventViewViewModel: ObservableObject{
    var event: Event
    
    var dateText: String{
        if Calendar.current.isDateInToday(Date(timeIntervalSince1970: event.date)){
            return "Today"
        } else if Calendar.current.isDateInTomorrow(Date(timeIntervalSince1970: event.date)) {
            return "Tomorrow"
        } else {
            let date = Date(timeIntervalSince1970: event.date)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            
            return date.formatted(Date.FormatStyle().weekday(.wide)) + ", " + formatter.string(from: date)
        }
    }
    
    init(event: Event) {
        self.event = event
    }
}
