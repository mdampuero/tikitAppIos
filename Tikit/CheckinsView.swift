import SwiftUI
import AudioToolbox

struct CheckinsView: View {
    let session: EventSession
    let eventID: Int
    @EnvironmentObject var sessionManager: SessionManager
    @State private var checkins: [CheckinData] = []
    @State private var isLoading = false
    @State private var isShowingScanner = false
    @State private var showResultAlert = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""
    @State private var resultCheckin: CheckinResponse?
    @State private var resultRegistrantType: SessionRegistrantType?
    @State private var isSuccess = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header compacto con info de sesión
                VStack(alignment: .leading, spacing: 8) {
                    // Nombre de sesión
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 8)
                        Text(session.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Información de fecha
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Inicio")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let startDate = session.startDate {
                                Text(formatDateTime(startDate: startDate, startTime: session.startTime))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            } else {
                                Text("-")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fin")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let endDate = session.endDate {
                                Text(formatDateTime(startDate: endDate, startTime: session.endTime))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            } else {
                                Text("-")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                
                // Listado de checkins
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Check-ins (\(checkins.count))")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if checkins.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("Sin check-ins aún")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(checkins) { checkin in
                                    CheckinCard(checkin: checkin)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Botón flotante para escanear
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { isShowingScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.brandPrimary)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Check-ins")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingScanner) {
            QRScannerView(
                completion: { code in
                    isShowingScanner = false
                    Task { await registerCheckin(encryptedCode: code) }
                },
                onCancel: {
                    isShowingScanner = false
                }
            )
        }
        .alert(resultTitle, isPresented: $showResultAlert) {
            Button("Aceptar") {
                showResultAlert = false
                resultCheckin = nil
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            if isSuccess, let checkin = resultCheckin, let registrant = resultRegistrantType {
                Text("Nombre: \(checkin.guest.fullName)\nEmail: \(checkin.guest.email)\nTipo: \(registrant.registrantType.name)\nMétodo: \(checkin.method)")
            } else {
                Text(resultMessage)
            }
        }
        .onAppear {
            Task { await fetchCheckins() }
        }
    }
    
    private func fetchCheckins() async {
        guard let token = sessionManager.token, !isLoading else { return }
        isLoading = true
        
        let filter = "[{\"field\":\"e.session\",\"operator\":\"=\",\"value\":\(session.id)}]"
        let encodedFilter = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(APIConstants.baseURL)checkins?page=1&query=&limit=100&order=id:DESC&filter=\(encodedFilter)"
        
        guard let url = URL(string: urlString) else { isLoading = false; return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                isLoading = false
                return
            }
            let result = try JSONDecoder().decode(CheckinsResponse.self, from: data)
            checkins = result.data
        } catch {
            print("Error fetching checkins: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func registerCheckin(encryptedCode: String) async {
        guard let token = sessionManager.token else { return }
        
        guard let url = URL(string: APIConstants.baseURL + "checkins/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["eventSession": session.id, "guest": encryptedCode]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            
            let decoder = JSONDecoder()
            
            switch http.statusCode {
            case 201:
                if let checkin = try? decoder.decode(CheckinResponse.self, from: data) {
                    // Buscar el registrant type de esta sesión que coincida
                    let registrant = session.registrantTypes?.first(where: { $0.isActive })
                    
                    await MainActor.run {
                        AudioServicesPlaySystemSound(1108)
                        isSuccess = true
                        resultTitle = "✓ Check-in Exitoso"
                        resultCheckin = checkin
                        resultRegistrantType = registrant
                        resultMessage = ""
                        showResultAlert = true
                        
                        // Añadir a la lista
                        checkins.insert(CheckinData(
                            id: checkin.id,
                            guest: checkin.guest,
                            eventSession: checkin.eventSession,
                            method: checkin.method,
                            latitude: checkin.latitude,
                            longitude: checkin.longitude,
                            createdAt: checkin.createdAt,
                            updatedAt: checkin.updatedAt
                        ), at: 0)
                    }
                }
            case 403:
                await MainActor.run {
                    isSuccess = false
                    resultTitle = "✗ Error"
                    resultMessage = "Esta persona ya realizó check-in en esta sesión."
                    showResultAlert = true
                }
            case 404:
                await MainActor.run {
                    isSuccess = false
                    resultTitle = "✗ Error"
                    resultMessage = "No se encontró a esta persona en el registro."
                    showResultAlert = true
                }
            case 400:
                await MainActor.run {
                    isSuccess = false
                    resultTitle = "✗ Error"
                    resultMessage = "Solicitud inválida. El registrante o la sesión no existen."
                    showResultAlert = true
                }
            default:
                let apiError = try? decoder.decode(CheckinAPIErrorResponse.self, from: data)
                let errorMessage = apiError?.message ?? apiError?.error ?? "Error desconocido"
                await MainActor.run {
                    isSuccess = false
                    resultTitle = "✗ Error"
                    resultMessage = errorMessage
                    showResultAlert = true
                }
            }
        } catch {
            await MainActor.run {
                isSuccess = false
                resultTitle = "✗ Error"
                resultMessage = error.localizedDescription
                showResultAlert = true
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "dd MMM yyyy"
        display.locale = Locale(identifier: "es_ES")
        return display.string(from: date)
    }
    
    private func formatDateTime(startDate: String, startTime: String?) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: startDate) else { return startDate }
        
        let dateDisplay = DateFormatter()
        dateDisplay.dateFormat = "dd MMM yyyy"
        dateDisplay.locale = Locale(identifier: "es_ES")
        let formattedDate = dateDisplay.string(from: date)
        
        // Si hay hora, extraerla y mostrar
        if let timeString = startTime {
            let timeFormatter = ISO8601DateFormatter()
            if let timeDate = timeFormatter.date(from: timeString) {
                let timeDisplay = DateFormatter()
                timeDisplay.dateFormat = "HH:mm"
                let formattedTime = timeDisplay.string(from: timeDate)
                return "\(formattedDate) \(formattedTime)"
            }
        }
        
        return formattedDate
    }
}

struct CheckinCard: View {
    let checkin: CheckinData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Nombre del guest
            Text(checkin.guest.fullName)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Email
            HStack(spacing: 6) {
                Image(systemName: "envelope.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                Text(checkin.guest.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Método y hora
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text(checkin.method)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
                
                if let createdAt = checkin.createdAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text(formatTime(createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "HH:mm"
        display.locale = Locale(identifier: "es_ES")
        return display.string(from: date)
    }
}

#Preview {
    CheckinsView(
        session: EventSession(id: 1, name: "Sesión Demo", description: nil, createdAt: nil, updatedAt: nil, isDefault: nil, startDate: "2026-03-01T00:00:00+00:00", startTime: nil, endDate: "2026-04-30T00:00:00+00:00", endTime: nil, registrantTypes: nil),
        eventID: 6
    )
    .environmentObject(SessionManager())
}
