//
//  ChoreStore.swift
//  RoomieMatter
//
//  Created by Teresa Lee on 7/11/2023.
//

import Foundation
import SwiftUI
import Observation

@Observable
final class ChoreStore {
    static let shared = ChoreStore()

    //  Placeholders
    
//    private static let dateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        return formatter
//    }()
    
    private(set) var chores: [Chore] = [
        Chore(name: "Vacuum", date: "Thursday", assignee: "Teresa"),
        Chore(name: "Take Trash", date: "Friday!", assignee: "Alex"),
        ]

}
