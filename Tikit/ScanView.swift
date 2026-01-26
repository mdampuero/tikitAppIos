import SwiftUI
import AudioToolbox

struct ScanView: View {
    let session: EventSession
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isShowingScanner = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertCheckin: CheckinResponse?
    @State private var isSuccess = false

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Image(systemName: "qrcode.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.blue)
                    .onTapGesture { isShowingScanner = true }
                Spacer()
            }
        }
        .navigationTitle("Escanear")
        .fullScreenCover(isPresented: $isShowingScanner) {
            QRScannerView(
                completion: { code in
                    isShowingScanner = false
                    handleScan(code)
                },
                onCancel: {
                    isShowingScanner = false
                }
            )
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Aceptar") {
                showAlert = false
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            if let checkin = alertCheckin {
                Text(alertMessage + "\n\nNombre: \(checkin.guest.fullName)\nCorreo: \(checkin.guest.email)\nSesión: \(checkin.eventSession.name)\nMétodo: \(checkin.method)")
            } else {
                Text(alertMessage)
            }
        }
    }

    private func handleScan(_ code: String) {
        print("DEBUG ScanView: Código QR escaneado: \(code)")
        Task { await register(encryptedCode: code) }
    }

    private func register(encryptedCode: String) async {
        guard let token = sessionManager.token else {
            print("DEBUG: No token available")
            await MainActor.run {
                showResult(success: false, message: "No se pudo hacer check-in", checkin: nil)
            }
            return
        }
        
        print("DEBUG: Token disponible: \(token.prefix(20))...")
        print("DEBUG: EventSession ID: \(session.id)")
        print("DEBUG: Guest (encrypted): \(encryptedCode)")
        
        guard let url = URL(string: APIConstants.baseURL + "checkins/register") else {
            print("DEBUG: URL inválida")
            return
        }
        
        print("DEBUG: URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["eventSession": session.id, "guest": encryptedCode]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("DEBUG: Request body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let bodyString = String(data: data, encoding: .utf8) {
                print("DEBUG: Response body: \(bodyString)")
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("DEBUG: No HTTPURLResponse")
                await MainActor.run {
                    showResult(success: false, message: "No se pudo hacer check-in", checkin: nil)
                }
                return
            }

            print("DEBUG: Status code: \(http.statusCode)")
            
            let decoder = JSONDecoder()

            switch http.statusCode {
            case 201:
                print("DEBUG: Attempting to decode CheckinResponse")
                if let checkin = try? decoder.decode(CheckinResponse.self, from: data) {
                    print("DEBUG: CheckinResponse decoded successfully")
                    await MainActor.run {
                        AudioServicesPlaySystemSound(1108)
                        showResult(success: true, message: "Check-in correcto", checkin: checkin)
                    }
                } else {
                    print("DEBUG: Failed to decode CheckinResponse")
                    await MainActor.run {
                        showResult(success: true, message: "Check-in correcto", checkin: nil)
                    }
                }
            case 403:
                await MainActor.run {
                    showResult(success: false, message: "Esta persona ya realizó check-in.", checkin: nil)
                }
            case 404:
                await MainActor.run {
                    showResult(success: false, message: "No se encontró a esta persona.", checkin: nil)
                }
            case 400:
                await MainActor.run {
                    showResult(success: false, message: "Solicitud inválida. El registrante o la sesión no existen.", checkin: nil)
                }
            default:
                print("DEBUG: Decoding error response for status \(http.statusCode)")
                let apiError = try? decoder.decode(CheckinAPIErrorResponse.self, from: data)
                let message = apiError?.message ?? apiError?.error ?? "No se pudo hacer check-in"
                print("DEBUG: Error message: \(message)")
                await MainActor.run {
                    showResult(success: false, message: message, checkin: nil)
                }
            }
        } catch {
            print("DEBUG: Catch error: \(error.localizedDescription)")
            await MainActor.run {
                showResult(success: false, message: "No se pudo hacer check-in", checkin: nil)
            }
        }
    }

    private func showResult(success: Bool, message: String, checkin: CheckinResponse?) {
        isSuccess = success
        alertTitle = success ? "✓ Éxito" : "✗ Error"
        alertMessage = message
        alertCheckin = checkin
        showAlert = true
    }
}

#Preview {
    ScanView(session: EventSession(id: 0, name: "Demo", description: nil, createdAt: nil, updatedAt: nil, isDefault: nil, startDate: nil, startTime: nil, endDate: nil, endTime: nil))
        .environmentObject(SessionManager())
}

