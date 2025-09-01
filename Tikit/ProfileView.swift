import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let urlString = session.user?.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding(.top, 40)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }
                Form {
                    Section {
                        profileRow(title: "Nombre", value: session.user?.firstName)
                        profileRow(title: "Apellido", value: session.user?.lastName)
                        profileRow(title: "Email", value: session.user?.email)
                        if let phone = session.user?.phone {
                            profileRow(title: "Teléfono", value: phone)
                        }
                        if let company = session.user?.company {
                            profileRow(title: "Compañía", value: company)
                        }
                    }
                }
                .frame(maxHeight: 300)
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
    private func profileRow(title: String, value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "").foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView().environmentObject(SessionManager())
}
