import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ProfileView()
                .tabItem {
                    Label("Mi cuenta", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainView().environmentObject(SessionManager())
}
