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
    @State private var isLoading = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    Spacer().frame(height: geo.size.height * 0.25)
                    Image(colorScheme == .dark ? "LogoDark" : "LogoLight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.5)
                    Text("Bienvenido a Tikit")
                        .font(.title2)
                        .bold()
                        .padding(.top, 16)
                    Text("Tu administrador de eventos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Spacer()
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("", text: $email)
                                .focused($focusedField, equals: .email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .placeholder(when: email.isEmpty && focusedField != .email) {
                                    Text("Email").foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(emailError != nil && focusedField != .email ? Color.red : Color.clear, lineWidth: 1)
                                )
                                .disabled(isLoading)
                            if let emailError = emailError {
                                Text(emailError)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    TextField("", text: $password)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("", text: $password)
                                        .focused($focusedField, equals: .password)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                            .placeholder(when: password.isEmpty && focusedField != .password) {
                                Text("Contraseña").foregroundColor(.gray)
                                    .padding(.leading, 4)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(passwordError != nil && focusedField != .password ? Color.red : Color.clear, lineWidth: 1)
                            )
                            .disabled(isLoading)
                            if let passwordError = passwordError {
                                Text(passwordError)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                        Button(action: { Task { await handleLogin() } }) {
                            if isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Iniciar sesión")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(isLoading)

                        Button("Iniciar sesión con Google") {
                            handleGoogle()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 40)
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

    @MainActor
    func handleLogin() async {
        if email.isEmpty {
            emailError = "Email requerido"
        } else if !isValidEmail(email) {
            emailError = "Email inválido"
        } else {
            emailError = nil
        }
        passwordError = password.isEmpty ? "Contraseña requerida" : nil
        guard emailError == nil && passwordError == nil else { return }
        isLoading = true
        if let apiError = await session.login(email: email, password: password) {
            let fieldErrors = apiError.fieldErrors
            emailError = fieldErrors["email"]
            passwordError = fieldErrors["password"]
            if fieldErrors.isEmpty {
                showToast(apiError.message ?? "Error del servidor")
            }
        }
        isLoading = false
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

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: email)
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
