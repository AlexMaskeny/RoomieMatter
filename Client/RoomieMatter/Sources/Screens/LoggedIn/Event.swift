//
//  Event.swift
//  RoomieMatter
//
//  Created by Anish Sundaram on 11/28/23.
//

import Foundation
import FirebaseFunctions
import GoogleSignIn


 struct Event: Identifiable{
     let id: String
     var name: String
     var date: Double
     var description: String
     var author: Roommate
     var Guests: [Roommate]

     static let Example1 = Event(id: "1", name: "Michigan vs Ohio State Game", date: Date().timeIntervalSince1970 , description: "Make sure you wear Maize and Blue. We are going to be in the 3rd row towards the field goal post. Hope to see you there!.", author: Roommate.Example2, Guests: [Roommate.Example1, Roommate.Example2, Roommate.Example3, Roommate.Example4])


     static let Example2 = Event(id: "2", name: "Dinner at Slurping Turtle", date: Date().timeIntervalSince1970 + 86400, description: "Getting Dinner to celebrate an app well made!", author: Roommate.Example2, Guests: [Roommate.Example1, Roommate.Example2])

     func checkContains(roommate: Roommate) -> Bool{
         Guests.contains { roommate1 in
             roommate1.id == roommate.id
         }
     }
 }

func getEvents() {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return
    }
    let token = user.accessToken.tokenString
    print(token)
    
    Functions.functions().httpsCallable("getEvents").call(["token": token]) { (result, error) in
        print("in getEvents")
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

func addEvent() {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return
    }
    let token = user.accessToken.tokenString
    print(token)
    
    let data: [String: Any] = ["token": token, "eventName": "event1", "startDatetime": "2023-12-05T09:00:00-05:00",
                               "endDatetime": "2023-12-05T10:00:00-05:00", "description": "gibberish", "guests": ["uqWhv6HG6QPqjGyJV2a9FF6R1pm2"]]
    Functions.functions().httpsCallable("addEvent").call(data) { (result, error) in
        print("in addEvent")
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

func editEvent() {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return
    }
    let token = user.accessToken.tokenString
    print(token)
    
    let data: [String: Any] = ["token": token, "eventId": "ht742trjvndivfttg1vp622f34", "eventName": "event2", "startDatetime": "2023-12-04T22:00:00-05:00", "endDatetime": "2023-12-04T23:00:00-05:00", "description": "new description", "guests": ["uqWhv6HG6QPqjGyJV2a9FF6R1pm2"]]
//    let data: [String: Any] = ["token": token, "eventId": "ht742trjvndivfttg1vp622f34", "eventName": "new name here"]
    Functions.functions().httpsCallable("editEvent").call(data) { (result, error) in
        print("in editEvent")
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

func deleteEvent() {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return
    }
    let token = user.accessToken.tokenString
    print(token)
    
    Functions.functions().httpsCallable("deleteEvent").call(["token": token, "eventId": "ht742trjvndivfttg1vp622f34"]) { (result, error) in
        print("in deleteEvent")
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
