import SwiftUI
import AudioToolbox

struct ScanView: View {
    let session: EventSession
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isShowingScanner = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showResult = false
    @State private var resultSuccess = false
    @State private var resultMessage = ""
    @State private var latestCheckin: CheckinResponse?

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
            if showToast {
                VStack { Spacer(); ToastView(message: toastMessage).padding(.bottom, 40) }
                    .transition(.opacity)
            }
            if showResult {
                ResultView(success: resultSuccess, message: resultMessage, checkin: latestCheckin)
                    .transition(.scale)
            }
        }
        .navigationTitle("Escanear")
        .fullScreenCover(isPresented: $isShowingScanner) {
            QRScannerView { code in
                isShowingScanner = false
                handleScan(code)
            }
        }
    }

    private func handleScan(_ code: String) {
        guard let guestId = Int(code) else {
            showToast(message: "Código inválido")
            return
        }
        Task { await register(guestId: guestId) }
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showToast = false }
        }
    }

    private func register(guestId: Int) async {
        guard let token = sessionManager.token else {
            await MainActor.run {
                showResult(success: false, message: "No se pudo hacer check-in", checkin: nil)
            }
            return
        }
        guard let url = URL(string: "https://tikit.cl/api/checkins/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = ["eventSession": session.id, "guest": guestId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                await MainActor.run {
                    showResult(success: false, message: "No se pudo hacer check-in", checkin: nil)
                }
                return
            }

            let decoder = JSONDecoder()

            switch http.statusCode {
            case 200:
                if let checkin = try? decoder.decode(CheckinResponse.self, from: data) {
                    await MainActor.run {
                        AudioServicesPlaySystemSound(1108)
                        showResult(success: true, message: "Check-in correcto", checkin: checkin)
                    }
                } else {
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
                let apiError = try? decoder.decode(CheckinAPIErrorResponse.self, from: data)
                let message = apiError?.message ?? apiError?.error ?? "No se pudo hacer check-in"
                await MainActor.run {
                    showResult(success: false, message: message, checkin: nil)
                }
            }
        } catch {
            await MainActor.run {
                showResult(success: false, message: "No se pudo hacer check-in", checkin: nil)
            }
        }
    }

    private func showResult(success: Bool, message: String, checkin: CheckinResponse?) {
        resultSuccess = success
        resultMessage = message
        latestCheckin = checkin
        withAnimation { showResult = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showResult = false }
        }
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct ResultView: View {
    let success: Bool
    let message: String
    let checkin: CheckinResponse?

    private var iconName: String { success ? "checkmark.circle.fill" : "xmark.octagon.fill" }
    private var color: Color { success ? .green : .red }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(color)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            if success, let checkin {
                CheckinDetailView(checkin: checkin)
            }
        }
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

struct CheckinDetailView: View {
    let checkin: CheckinResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailRow(title: "Nombre", value: checkin.guest.fullName)
            DetailRow(title: "Correo", value: checkin.guest.email)
            DetailRow(title: "Sesión", value: checkin.eventSession.name)
            DetailRow(title: "Método", value: checkin.method)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    struct DetailRow: View {
        let title: String
        let value: String

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    ScanView(session: EventSession(id: 0, name: "Demo", description: nil, createdAt: nil, updatedAt: nil, isDefault: nil, startDate: nil, startTime: nil, endDate: nil, endTime: nil))
        .environmentObject(SessionManager())
}

