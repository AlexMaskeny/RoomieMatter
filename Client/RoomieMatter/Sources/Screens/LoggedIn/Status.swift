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


func editStatus(status: String) -> String {
    let authViewModel = AuthenticationViewModel.shared
    guard let user = GIDSignIn.sharedInstance.currentUser else {
        print("User not properly signed in")
        return "error"
    }
    let token = user.accessToken.tokenString
    let params = [
        "token": token,
        "userId": authViewModel.user_uid,
        "roomId": authViewModel.room_id,
        "status": status.lowercased()
    ]
    
    print(authViewModel.user_uid,authViewModel.room_id, status)

    Functions.functions().httpsCallable("changeStatus").call(params) { (result, error) in
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
