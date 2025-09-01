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
                        Button(action: handleGoogle) {
                            HStack(spacing: 8) {
                                GoogleLogo()
                                    .frame(width: 20, height: 20)
                                Text("Iniciar con Google")
                                    .foregroundColor(.black)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }
                        .frame(width: geo.size.width * 0.6)
                        .background(Color.white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        .disabled(isLoading)

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
                            Group {
                                if isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Iniciar sesión")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .cornerRadius(8)
                        }
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

struct GoogleLogo: View {
    var body: some View {
        GeometryReader { geo in
            let lineWidth = geo.size.width * 0.25
            let radius = geo.size.width / 2
            ZStack {
                // Blue
                Path { path in
                    path.addArc(center: CGPoint(x: radius, y: radius), radius: radius - lineWidth/2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                }
                .stroke(Color(red: 66/255, green: 133/255, blue: 244/255), lineWidth: lineWidth)

                // Red
                Path { path in
                    path.addArc(center: CGPoint(x: radius, y: radius), radius: radius - lineWidth/2, startAngle: .degrees(-45), endAngle: .degrees(90), clockwise: false)
                }
                .stroke(Color(red: 219/255, green: 68/255, blue: 55/255), lineWidth: lineWidth)

                // Yellow
                Path { path in
                    path.addArc(center: CGPoint(x: radius, y: radius), radius: radius - lineWidth/2, startAngle: .degrees(-90), endAngle: .degrees(-45), clockwise: false)
                }
                .stroke(Color(red: 244/255, green: 180/255, blue: 0/255), lineWidth: lineWidth)

                // Green
                Path { path in
                    path.addArc(center: CGPoint(x: radius, y: radius), radius: radius - lineWidth/2, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
                }
                .stroke(Color(red: 15/255, green: 157/255, blue: 88/255), lineWidth: lineWidth)

                // Horizontal bar for G
                Path { path in
                    path.move(to: CGPoint(x: radius, y: radius))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.9, y: radius))
                }
                .stroke(Color(red: 66/255, green: 133/255, blue: 244/255), lineWidth: lineWidth)
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
