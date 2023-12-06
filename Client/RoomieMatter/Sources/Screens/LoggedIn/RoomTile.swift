//
//  SelectRoomView.swift
//  RoomieMatter
//
//  Created by Tanuj Koli on 11/12/23.
//

import Foundation
import SwiftUI

struct TileView: View {
    var creatorName: String
    var roomName: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(roomName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
            HStack() {
                VStack() {
                    HStack {
                        Text("Created by")
                            .italic()
                            .foregroundColor(.gray)
                        Text(creatorName)
                            .italic()
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                }
                Spacer()
                Button(action: {
                    print("Right arrow tapped")
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20))
                        .padding(.trailing, 16)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    //Loop when pulling from git
                    
//                    ForEach(chore.assignedRoommates, id: \.name){ _ in
//                        Image(systemName: "person.fill")
//                            .font(.headline)
//                            .padding(10)
//                            .background(
//                                Circle()
//                                    .foregroundStyle(.white)
//                                    .overlay(
//                                        Circle()
//                                            .stroke()
//                                    )
//                            )
//                    }
                    Image(systemName: "person.fill")
                        .font(.headline)
                        .padding(10)
                        .background(
                            Circle()
                                .foregroundStyle(.white)
                                .overlay(
                                    Circle()
                                        .stroke()
                                )
                        )
                    Image(systemName: "person.fill")
                        .font(.headline)
                        .padding(10)
                        .background(
                            Circle()
                                .foregroundStyle(.white)
                                .overlay(
                                    Circle()
                                        .stroke()
                                )
                        )
                    Image(systemName: "person.fill")
                        .font(.headline)
                        .padding(10)
                        .background(
                            Circle()
                                .foregroundStyle(.white)
                                .overlay(
                                    Circle()
                                        .stroke()
                                )
                        )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding()
        .background(Color(white: 0.9))
        .cornerRadius(10)
    }
}

