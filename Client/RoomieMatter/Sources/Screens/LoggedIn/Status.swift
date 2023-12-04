//
//  Status.swift
//  RoomieMatter
//
//  Created by Anish Sundaram on 12/3/23.
//

import SwiftUI
import Foundation
import Observation
import FirebaseFunctions
import GoogleSignIn


enum Status{
    case studying
    case home
    case sleeping
    case notHome
    
    var color: Color{
        switch self {
        case .studying:
            Color.red
        case .home:
            Color.green
        case .sleeping:
            Color.blue
        case .notHome:
            Color.gray
        }
    }
    
    var status: String{
        switch self {
        case .studying:
            "Studying"
        case .home:
            "At Home"
        case .sleeping:
            "Sleeping"
        case .notHome:
            "Not Home"
        }
    }
}


func interpretString(status: String) -> Status{
    switch status{
    case "at home":
        return .home
    case "studying":
        return .studying
    case "sleeping":
        return .sleeping
    case "not home":
        return .notHome
    default:
        return .home
    }
}



func editStatus(userID: String?, roomID: String?, status: String) -> String {
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return "error"
    }
    let token = user.accessToken.tokenString
    let data: [String: Any] = [
        "token": token,
        "userId": userID,
        "roomId": roomID,
        "status": status,
    ]

    Functions.functions().httpsCallable("changeStatus").call(data) { (result, error) in
        print("in changeStatus")
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

    return "editStatus: 1"
}
