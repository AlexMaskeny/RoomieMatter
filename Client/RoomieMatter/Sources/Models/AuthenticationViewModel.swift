//
//  AuthenticationViewModel.swift
//  RoomieMatter
//
//  Created by David Wang on 11/5/23.
//

import SwiftUI
import Firebase
import Observation

@Observable class AuthenticationViewModel {
    var username: String?

    init() {
        updateUsername()
    }

    func updateUsername() {
        if let currentUser = Auth.auth().currentUser {
            username = currentUser.displayName
        } else {
            username = nil
        }
    }

    func refresh() {
        updateUsername()
    }

}

