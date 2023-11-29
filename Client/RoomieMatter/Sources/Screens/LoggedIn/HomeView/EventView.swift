

import SwiftUI

struct EventView: View {
    @StateObject var viewModel: EventViewViewModel
    var body: some View {
        VStack(alignment: .leading){
            Text(viewModel.event.name)
                .font(.headline)
            Text(viewModel.dateText)
                .font(.subheadline)
            
            
            HStack {
                ForEach(viewModel.event.Guests){roommate in
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
    
    init(event: Event){
        self._viewModel = StateObject(wrappedValue: EventViewViewModel(event: event))
    }
}

#Preview {
    EventView(event: Event.Example1)
}
