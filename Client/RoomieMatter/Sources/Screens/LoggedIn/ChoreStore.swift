//
//  ChoreStore.swift
//  RoomieMatter
//
//  Created by Teresa Lee on 11/11/2023.
//

import Foundation
import Observation
import FirebaseFunctions

@Observable
final class ChoreStore {
    static let shared = ChoreStore()
    private init() {}
    
    private(set) var chores = [Chore]()
    private let nFields = Mirror(reflecting: Chore()).children.count
    
    func getChores() {
        Functions.functions().httpsCallable("getChores").call() { (result, error) in
           if let error = error as NSError? {
               if error.domain == FunctionsErrorDomain {
                   let code = FunctionsErrorCode(rawValue: error.code)
                   let message = error.localizedDescription
                   let details = error.userInfo[FunctionsErrorDetailsKey]
                   print("Error: \(message)")
               }
               // Handle the error
           }
           if let data = result?.data as? Data {
                // Deserialize the data to a [String: Any] dictionary
                guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("getChatts: failed JSON deserialization")
                    return
                }
                print(jsonObj)
                let choresReceived = jsonObj["chores"] as? [[String?]] ?? []

                // data = [summary, startDate, frequency, assignee]
                DispatchQueue.main.async {
                   self.chores = [Chore]()
                   for choreEntry in choresReceived {
                       if choreEntry.count == self.nFields {
                           self.chores.append(Chore(name: choreEntry[0],
                                                    date: choreEntry[1],
                                                    description: choreEntry[2],
                                                    assignedRoomates: choreEntry[2]))
                       } else {
                           print("getChores: Received unexpected number of fields: \(choreEntry.count) instead of \(self.nFields).")
                       }
                   }
               }
            }
        }
    }
}

