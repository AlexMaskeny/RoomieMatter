//
//  ChatStore.swift
//  RoomieMatter
//
//  Created by David Wang on 10/31/23.
//

import SwiftUI

import Observation

@Observable
final class ChatStore {
    static let shared = ChatStore()

    private(set) var chats = [Chat]()

}
