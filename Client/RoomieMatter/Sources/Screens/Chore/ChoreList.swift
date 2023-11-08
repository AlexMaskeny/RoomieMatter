//
//  ChoreList.swift
//  RoomieMatter
//
//  Created by Teresa Lee on 7/11/2023.
//

import Foundation
import SwiftUI

struct ChoreList: View {
    let chore: Chore
    
    var body: some View {
        VStack(alignment: .leading) {
            if let name = chore.name, let date = chore.date, let assignee = chore.assignee {
                Text(name).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
                Spacer()
                Text(date).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
                Spacer()
                Text(assignee).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).font(.system(size: 14))
            }
        }
    }
}
