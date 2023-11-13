//
//  MenuView.swift
//  RoomieMatter
//
//  Created by Tanuj Koli on 11/12/23.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ContentView: View {
    @State private var homeButtonColor: Color = .blue
    @State private var calendarButtonColor: Color = .black
    @State private var profileButtonColor: Color = .black

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                //home button
                Button(action: { resetCalendarProfile() }) {
                    Image(systemName: "house.fill")
                        .foregroundColor(homeButtonColor)
                        .font(.system(size: 30))
                }
                Spacer()

                //calendar button
                Button(action: { resetHomeProfile() }) {
                    Image(systemName: "calendar")
                        .foregroundColor(calendarButtonColor)
                        .font(.system(size: 30))
                }
                Spacer()

                //profile button
                Button(action: { resetHomeCalendar() }) {
                    Image(systemName: "person.fill")
                        .foregroundColor(profileButtonColor)
                        .font(.system(size: 30))
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            Spacer()
        }
    }

    private func resetCalendarProfile() {
        homeButtonColor = .blue
        calendarButtonColor = .black
        profileButtonColor = .black
    }
    private func resetHomeProfile() {
        homeButtonColor = .black
        calendarButtonColor = .blue
        profileButtonColor = .black
    }
    private func resetHomeCalendar() {
        homeButtonColor = .black
        calendarButtonColor = .black
        profileButtonColor = .blue
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
