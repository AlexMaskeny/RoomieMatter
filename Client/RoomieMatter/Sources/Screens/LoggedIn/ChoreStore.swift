//
//  ChoreStore.swift
//  RoomieMatter
//
//  Created by Teresa Lee on 11/11/2023.
//

import Foundation
import Observation
import FirebaseFunctions
import GoogleSignIn

//@Observable
//final class ChoreStore {
//    static let shared = ChoreStore()
//    private init() {}
//
//    private(set) var chores = [Chore]()
//    private let nFields = Mirror(reflecting: Chore()).children.count
//
//    func getChores() {
//        Functions.functions().httpsCallable("getChores").call() { (result, error) in
//           if let error = error as NSError? {
//               if error.domain == FunctionsErrorDomain {
//                   let code = FunctionsErrorCode(rawValue: error.code)
//                   let message = error.localizedDescription
//                   let details = error.userInfo[FunctionsErrorDetailsKey]
//                   print("Error: \(message)")
//               }
//               // Handle the error
//           }
//           if let data = result?.data as? Data {
//                // Deserialize the data to a [String: Any] dictionary
//                guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
//                    print("getChatts: failed JSON deserialization")
//                    return
//                }
//                print(jsonObj)
//                let choresReceived = jsonObj["chores"] as? [[String?]] ?? []
//
//                // data = [summary, startDate, frequency, assignee]
//                DispatchQueue.main.async {
//                   self.chores = [Chore]()
//                   for choreEntry in choresReceived {
//                       if choreEntry.count == self.nFields {
//                           self.chores.append(Chore(name: choreEntry[0],
//                                                    date: choreEntry[1],
//                                                    description: choreEntry[2],
//                                                    assignedRoomates: choreEntry[2]))
//                       } else {
//                           print("getChores: Received unexpected number of fields: \(choreEntry.count) instead of \(self.nFields).")
//                       }
//                   }
//               }
//            }
//        }
//    }
//}

func getChores() {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return
    }
    let token = user.accessToken.tokenString
    print(token)
    
    Functions.functions().httpsCallable("getChores").call(["token": token]) { (result, error) in
        print("in getChores")
        if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription
                let details = error.userInfo[FunctionsErrorDetailsKey]
                print("Error: \(message)")
            }
            // Handle the error
        }
        if let data = result?.data as? [String: Any] {
            print(data)
        }
    }
}

func addChore(name: String, date: Date, description: String, assignedRoommates: String) -> String {
//    let event = GTLRCalendar_Event()
//    event.summary = summary
//    event.descriptionProperty = description
//
//    let startDateTime = GTLRDateTime(date: startTime)
//    let endDateTime = GTLRDateTime(date: endTime)
//
//    event.start = GTLRCalendar_EventDateTime()
//    event.start?.dateTime = startDateTime
//
//    event.end = GTLRCalendar_EventDateTime()
//    event.end?.dateTime = endDateTime
//
//    let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: calendarId)
//    service?.executeQuery(query, completionHandler: { (_, _, error) in
//        if let error = error {
//            print("Error adding event: \(error.localizedDescription)")
//        } else {
//            print("Event added successfully")
//        }
//    })
    return "successfully added chore"
}

func deleteOneChore(chore_id: String, calendar_id: String) -> String {
//    let val = GTLR
//    let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarId, eventId: eventId)
//    service?.executeQuery(query, completionHandler: { (_, _, error) in
//        if let error = error {
//            print("Error deleting event: \(error.localizedDescription)")
//        } else {
//            print("Event deleted successfully")
//        }
//    })
    return "successfully deleted one chore"
}

func deleteAllInstancesOfEvent(eventId: String) -> String {
//    let query = GTLRCalendarQuery_EventsInstancesDelete.query(withCalendarId: calendarId, eventId: eventId)
//    service?.executeQuery(query, completionHandler: { (_, _, error) in
//        if let error = error {
//            print("Error deleting all instances of event: \(error.localizedDescription)")
//        } else {
//            print("All instances of event deleted successfully")
//        }
//    })
    return "successfully deleted all chores"
}
