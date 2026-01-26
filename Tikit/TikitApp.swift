import SwiftUI
import GoogleSignIn

@main
struct TikitApp: App {
    @StateObject var session = SessionManager()

    init() {
        // Configurar Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            //clientID: "331974773758-ms75sk3bv25vkfm0a7qao8ft0ur1kvep.apps.googleusercontent.com"
            clientID: "331974773758-28bc8jhftlnhvq3r5s7okb6agh2rflfu.apps.googleusercontent.com"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(session)
        }
    }
}
