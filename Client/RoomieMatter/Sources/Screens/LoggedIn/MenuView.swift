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
                Button(action: {
                    homeButtonColor = .black
                    resetButtonColors(except: homeButtonColor)
                }) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 30))
                }
                Spacer()
                
                //calendar button
                Button(action: {
                    calendarButtonColor = .blue
                    resetButtonColors(except: calendarButtonColor)
                }) {
                    Image(systemName: "calendar")
                        .foregroundColor(calendarButtonColor)
                        .font(.system(size: 30))
                }
                Spacer()

                //profile button
                Button(action: {
                    profileButtonColor = .purple
                    resetButtonColors(except: profileButtonColor)
                }) {
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

    private func resetButtonColors(except selectedColor: Color) {
        if homeButtonColor != selectedColor {
            homeButtonColor = .blue
        }
        if calendarButtonColor != selectedColor {
            calendarButtonColor = .blue
        }
        if profileButtonColor != selectedColor {
            profileButtonColor = .blue
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

