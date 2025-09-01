import SwiftUI

@main
struct TikitApp: App {
    @StateObject var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(session)
        }
    }
}
