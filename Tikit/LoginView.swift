import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Campos de sesión temporal (nuevos)
    @State private var sessionCode = ""
    @State private var sessionCodeError: String?
    @State private var showQRScanner = false
    
    // MARK: - Campos de login tradicional (comentados)
    // @State private var email = ""
    // @State private var password = ""
    // @State private var showPassword = false
    // @State private var emailError: String?
    // @State private var passwordError: String?
    
    @State private var toastMessage: String?
    @State private var isLoading = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case sessionCode
        // case email
        // case password
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    Spacer().frame(height: 60)

                    VStack(spacing: 16) {
                        Image(colorScheme == .dark ? "LogoDark" : "LogoLight")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)

                        Text("Bienvenido a Tikit")
                            .font(.title2)
                            .bold()

                        /* COMENTADO: Botón de Google
                        Button(action: handleGoogle) {
                            HStack(spacing: 8) {
                                Image("GoogleIcon")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Google")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .disabled(isLoading)
                        .padding(.top, 24)
                        */
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Nueva interfaz de código de sesión
                    VStack(alignment: .center, spacing: 16) {
                        // Leyenda explicativa
                        VStack(alignment: .center, spacing: 8) {
                            Text("Acceso temporal para check-ins")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Ingrese el código de sesión generado desde la plataforma web de Tikit. Este código le permitirá realizar check-ins de invitados durante las próximas 6 horas de manera segura y temporal.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 8)
                        }
                        
                        // Input de código de sesión
                        VStack(alignment: .center, spacing: 4) {
                            ZStack {
                                HStack {
                                    ZStack(alignment: .leading) {
                                        if sessionCode.isEmpty && focusedField != .sessionCode {
                                            Text("Código de sesión")
                                                .foregroundColor(.gray)
                                                .padding(.leading, 16)
                                        }
                                        TextField("", text: $sessionCode)
                                            .focused($focusedField, equals: .sessionCode)
                                            .keyboardType(.numberPad)
                                            .padding()
                                            .padding(.trailing, 40)
                                    }
                                    
                                    Spacer()
                                    
                                    // Botón de escanear QR
                                    Button(action: {
                                        showQRScanner = true
                                    }) {
                                        Image(systemName: "qrcode.viewfinder")
                                            .foregroundColor(.brandPrimary)
                                            .font(.system(size: 24))
                                            .frame(width: 44, height: 44)
                                    }
                                    .disabled(isLoading)
                                    .padding(.trailing, 8)
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(sessionCodeError != nil && focusedField != .sessionCode ? Color.red : Color.clear, lineWidth: 1)
                            )
                            .disabled(isLoading)
                            
                            if let error = sessionCodeError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                        
                        // Botón de validar
                        Button(action: { Task { await handleValidateSessionCode() } }) {
                            Group {
                                if isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Validar código")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                    
                    /* COMENTADO: Formulario de login tradicional
                    VStack(alignment: .leading, spacing: 16) {
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
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
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
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
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
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                    */
                    
                    Spacer()
                }
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
        .sheet(isPresented: $showQRScanner) {
            QRScannerView(
                completion: { scannedCode in
                    sessionCode = scannedCode
                    showQRScanner = false
                    sessionCodeError = nil
                },
                onCancel: {
                    showQRScanner = false
                }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Nueva función para validar código de sesión
    @MainActor
    func handleValidateSessionCode() async {
        sessionCodeError = nil
        
        if sessionCode.isEmpty {
            sessionCodeError = "El código de sesión es requerido"
            return
        }
        
        isLoading = true
        
        do {
            // Validar el código con la API
            _ = try await SessionCodeManager.shared.validateSessionCode(sessionCode.trimmingCharacters(in: .whitespacesAndNewlines))
            
            // Éxito - la redirección se manejará automáticamente en ContentView
            // El ContentView detectará la sesión temporal y navegará a CheckinsView
            
        } catch let error as NSError {
            // Manejar diferentes tipos de errores
            if error.code == 404 {
                sessionCodeError = "Código de sesión no encontrado"
            } else {
                sessionCodeError = error.localizedDescription
            }
        }
        
        isLoading = false
    }

    /* COMENTADO: Función de login tradicional
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
    */

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastMessage = nil
        }
    }

    /* COMENTADO: Validación de email (no se necesita por ahora)
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: email)
    }
    */
}

/* COMENTADO: Extensión placeholder (ya no se usa)
extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
*/
