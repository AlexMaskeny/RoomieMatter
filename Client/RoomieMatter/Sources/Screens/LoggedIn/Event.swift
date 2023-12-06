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
     var dateEnd: Double
     var description: String
     var author: Roommate
     var Guests: [Roommate]

     static let Example1 = Event(id: "1", name: "Michigan vs Ohio State Game", date: Date().timeIntervalSince1970, dateEnd: Date().timeIntervalSince1970 + 3600 , description: "Make sure you wear Maize and Blue. We are going to be in the 3rd row towards the field goal post. Hope to see you there!.", author: Roommate.Example2, Guests: [Roommate.Example1, Roommate.Example2, Roommate.Example3, Roommate.Example4])


     static let Example2 = Event(id: "2", name: "Dinner at Slurping Turtle", date: Date().timeIntervalSince1970 + 86400, dateEnd: Date().timeIntervalSince1970 + 86400 + 1800, description: "Getting Dinner to celebrate an app well made!", author: Roommate.Example2, Guests: [Roommate.Example1, Roommate.Example2])

     func checkContains(roommate: Roommate) -> Bool{
         Guests.contains { roommate1 in
             roommate1.id == roommate.id
         }
     }
 }

