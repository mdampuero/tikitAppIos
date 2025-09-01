import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.colorScheme) var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var toastMessage: String?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    Spacer().frame(height: geo.size.height * 0.25)
                    Image(colorScheme == .dark ? "LogoDark" : "LogoLight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.5)
                    Spacer()
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        if let emailError = emailError {
                            Text(emailError).foregroundColor(.red).font(.footnote)
                        }
                        HStack {
                            if showPassword {
                                TextField("Contraseña", text: $password)
                            } else {
                                SecureField("Contraseña", text: $password)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        if let passwordError = passwordError {
                            Text(passwordError).foregroundColor(.red).font(.footnote)
                        }
                        Button("Iniciar sesión") {
                            Task { await handleLogin() }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Iniciar sesión con Google") {
                            handleGoogle()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                }
                if let toast = toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.bottom, 40)
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    func handleLogin() async {
        emailError = email.isEmpty ? "Email requerido" : nil
        passwordError = password.isEmpty ? "Contraseña requerida" : nil
        guard emailError == nil && passwordError == nil else { return }
        if let error = await session.login(email: email, password: password) {
            showToast(error)
        }
    }

    func handleGoogle() {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else { return }
        Task {
            if let error = await session.loginWithGoogle(presenting: root) {
                showToast(error)
            }
        }
    }

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastMessage = nil
        }
    }
}
