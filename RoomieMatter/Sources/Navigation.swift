import SwiftUI

//basic programmatic navigation

enum Route: Hashable {
    case LoginScreen
    case InitialScreen
    case CreateAccount1
}

@Observable
final class NavigationState {
    var routes: [Route] = []
}
