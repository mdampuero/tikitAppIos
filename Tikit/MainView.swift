import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Eventos", systemImage: "list.bullet")
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
