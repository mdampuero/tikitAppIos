import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                Form {
                    Section {
                        profileRow(title: "Nombre", value: "John")
                        profileRow(title: "Apellido", value: "Doe")
                        profileRow(title: "Email", value: "john.doe@example.com")
                    }
                }
                .frame(maxHeight: 250)
                Spacer()
                Button(action: {
                    session.logout()
                }) {
                    Text("Salir")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Mi cuenta")
        }
    }

    @ViewBuilder
    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView().environmentObject(SessionManager())
}
