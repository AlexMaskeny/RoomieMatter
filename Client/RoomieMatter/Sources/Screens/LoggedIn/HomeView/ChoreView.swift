

import SwiftUI

struct ChoreView: View {
    @StateObject var viewModel: ChoreViewViewModel
    var body: some View {
        VStack(alignment: .leading){
            Text(viewModel.chore.name)
                .font(.headline)
            Text(viewModel.dateText)
                .font(.subheadline)
            
            
            HStack {
                ForEach(viewModel.chore.assignedRoommates){roommate in
                    if let image = roommate.image{
                        image
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .scaledToFill()
                            .overlay(
                                Circle()
                                    .stroke()
                            )
                    } else {
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
                    
                }
            }
            
        }
        .padding()
        .background(Color(white: 0.9))
        .cornerRadius(10)
    }
    
    init(chore: Chore){
        self._viewModel = StateObject(wrappedValue: ChoreViewViewModel(chore: chore))
    }
}

#Preview {
    ChoreView(chore: Chore.Example1)
}
