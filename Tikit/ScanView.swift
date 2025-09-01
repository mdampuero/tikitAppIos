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
                ResultView(success: resultSuccess, message: resultMessage)
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
            showResult(success: false, message: "No se pudo hacer checkin")
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
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                showResult(success: true, message: "Checkin correcto")
                AudioServicesPlaySystemSound(1108)
            } else {
                showResult(success: false, message: "No se pudo hacer checkin")
            }
        } catch {
            showResult(success: false, message: "No se pudo hacer checkin")
        }
    }

    private func showResult(success: Bool, message: String) {
        resultSuccess = success
        resultMessage = message
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
        }
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

#Preview {
    ScanView(session: EventSession(id: 0, name: "Demo", description: nil, createdAt: nil, updatedAt: nil, isDefault: nil, startDate: nil, startTime: nil, endDate: nil, endTime: nil))
        .environmentObject(SessionManager())
}

