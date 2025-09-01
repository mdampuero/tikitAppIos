import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            Text("Main Screen")
                .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
