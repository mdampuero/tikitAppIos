import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager

    private var displayName: String {
        let first = session.user?.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = session.user?.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let full = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? (session.user?.email ?? "Tu cuenta") : full
    }

    private var subtitle: String {
        guard let role = session.user?.role, !role.isEmpty else {
            return session.user?.email ?? ""
        }
        // Ocultar role_admin para evitar mostrar privilegios internos
        if role.lowercased() == "role_admin" {
            return session.user?.email ?? ""
        }
        return role.capitalized
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                LinearGradient(colors: [.brandPrimary.opacity(0.9), .brandSecondary.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        infoCard

                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Mi cuenta")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            avatarView
            Text(displayName)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 8)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Datos personales")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 10) {
                infoRow(icon: "person.fill", title: "Nombre", value: session.user?.firstName)
                infoRow(icon: "person.text.rectangle", title: "Apellido", value: session.user?.lastName)
                infoRow(icon: "envelope.fill", title: "Email", value: session.user?.email)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: { session.logout() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Cerrar sesión")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.9))
                .foregroundColor(.brandPrimary)
                .cornerRadius(12)
            }
        }
        .padding(.top, 4)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 130, height: 130)

            if let urlString = session.user?.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.7))
                        .padding(28)
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundColor(.white)
                    .padding(24)
                    .background(Circle().fill(Color.white.opacity(0.18)))
            }
        }
    }

    private func infoRow(icon: String, title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.brandPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(value?.isEmpty == false ? value! : "No disponible")
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ProfileView().environmentObject(SessionManager())
}
