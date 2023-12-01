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
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return "error"
    }
    let token = user.accessToken.tokenString
    print(token)
    
    /* required arguments: token, eventName, date, frequency
     * optional arguments: endRecurrenceDate, description, assignedRoommates
     * (endRecurrenceDate is ignored for frequency == Once)
     * frequency = {Once, Daily, Weekly, Biweekly, Monthly}
     *
     * example for required arguments:
     * let data: [String: Any] = ["token": token, "eventName": "Dishes", "date": "2023-12-02", "frequency": "Once"]
     *
     * example for all arguments is listed below:
     */
    
    let data: [String: Any] = ["token": token, "eventName": "Trash", "date": "2023-12-02", "frequency": "Biweekly",
                "endRecurrenceDate": "2023-12-30", "description": "gibberish", "assignedRoommates": ["lteresa@umich.edu"]]
    // is it easier for frontend if we take in UUID instead of email for each user?
    
    Functions.functions().httpsCallable("addChore").call(data) { (result, error) in
        print("in addChore")
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
    
    return "return something here"
}

func deleteOneInstanceOfChore(chore_id: String, calendar_id: String) -> String {
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

func deleteChore(eventId: String) -> String {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return "error"
    }
    let token = user.accessToken.tokenString
    print(token)
    
    /* required arguments: token, eventId
     * example argument is listed below:
     */
    let data = ["token": token, "eventId": "to971io3dt6a6360370nrvnaus"]
    
    Functions.functions().httpsCallable("deleteChore").call(data) { (result, error) in
        print("in deleteChore")
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
    
    return "return something here"
}
