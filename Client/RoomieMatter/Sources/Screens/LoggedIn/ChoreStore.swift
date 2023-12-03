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

func getChore(instanceId: String) {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return
    }
    let token = user.accessToken.tokenString
    print(token)
    
    Functions.functions().httpsCallable("getChore").call(["token": token, "instanceId": instanceId]) { (result, error) in
        print("in getChore")
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
    
    let data: [String: Any] = ["token": token, "eventName": "Trash", "date": "2023-12-02", "frequency": "Weekly",
                "endRecurrenceDate": "2023-12-30", "description": "gibberish", "assignedRoommates": ["uqWhv6HG6QPqjGyJV2a9FF6R1pm2"]]

    
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

func editChore(name: String, date: Date, description: String, assignedRoommates: String) -> String {
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
    
    let data: [String: Any] = ["token": token, "instanceId": "fpkh4gu4f80j3noorhassgg6g4_20231205", "eventName": "Trash", "date": "2023-12-03", "frequency": "Weekly",
                "endRecurrenceDate": "2023-12-30", "description": "gibberish", "assignedRoommates": ["uqWhv6HG6QPqjGyJV2a9FF6R1pm2"]]
    
    Functions.functions().httpsCallable("editChore").call(data) { (result, error) in
        print("in editChore")
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

func completeChore(instanceId: String) -> String {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return "error"
    }
    let token = user.accessToken.tokenString
    print(token)
    
    /* required arguments: token, instanceId*/
    let data = ["token": token, "instanceId": instanceId]
    
    Functions.functions().httpsCallable("completeChore").call(data) { (result, error) in
        print("in completeChore")
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

func deleteChore(instanceId: String) -> String {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return "error"
    }
    let token = user.accessToken.tokenString
    print(token)
    
    /* required arguments: token, instanceId*/
    let data = ["token": token, "instanceId": instanceId]
    
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
