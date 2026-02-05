import SwiftUI
import AudioToolbox
import OSLog

struct CheckinsView: View {
    let session: EventSession
    let eventID: Int
    let eventName: String
    var onLogout: (() -> Void)? = nil // Callback para sesión temporal
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
    @State private var selectedCheckin: CheckinData?
    @State private var checkinError: CheckinError?
    @State private var showCategoryFilter = false
    @State private var selectedCategoryIds: Set<Int> = []
    @State private var allCategoriesSelected = true
    @State private var showLogoutConfirmation = false
    private let logger = Logger(subsystem: "com.tikit", category: "CheckinsView")
    
    private var availableCategories: [SessionRegistrantType] {
        session.registrantTypes?.filter { $0.isActive } ?? []
    }
    
    private var totalCheckinsInSession: Int {
        checkins.count
    }
    
    private var totalRegisteredInSession: Int {
        guard let registrantTypes = session.registrantTypes else { return 0 }
        return registrantTypes.reduce(0) { $0 + ($1.registered ?? 0) }
    }
    
    // Obtener token (de sesión normal o API para sesión temporal)
    private func getAuthToken() async -> String? {
        // Si hay sesión normal, usar ese token
        if let token = sessionManager.token {
            return token
        }
        
        // Si es sesión temporal, obtener token de API
        if onLogout != nil {
            do {
                return try await SessionCodeManager.shared.loginWithAPICredentials()
            } catch {
                print("❌ Error obteniendo token de API: \(error.localizedDescription)")
                return nil
            }
        }
        
        return nil
    }
    
    struct CheckinError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header compacto con info de sesión
                VStack(alignment: .leading, spacing: 12) {
                    // Nombre del evento
                    Text(eventName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
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
                .transaction { transaction in
                    transaction.animation = nil
                }
                
                // Listado de checkins
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Check-ins (\(totalCheckinsInSession)/\(totalRegisteredInSession))")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                    
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
                                    CheckinCard(
                                        checkin: checkin,
                                        registrantType: session.registrantTypes?.first(where: { $0.isActive })
                                    )
                                    .onTapGesture {
                                        selectedCheckin = checkin
                                    }
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Check-ins")
        .toolbar {
            if let onLogout = onLogout {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showLogoutConfirmation = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCategoryFilter = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .alert("Cerrar sesión", isPresented: $showLogoutConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Salir", role: .destructive) {
                onLogout?()
            }
        } message: {
            Text("¿Está seguro que desea cerrar la sesión temporal? Deberá ingresar un nuevo código para acceder nuevamente.")
        }
        .sheet(isPresented: $showCategoryFilter) {
            CategoryFilterView(
                categories: availableCategories,
                selectedCategoryIds: $selectedCategoryIds,
                allCategoriesSelected: $allCategoriesSelected,
                sessionId: session.id
            )
        }
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
        .sheet(isPresented: $showResultAlert) {
            if isSuccess, let checkin = resultCheckin, let registrant = resultRegistrantType {
                CheckinSuccessView(
                    checkin: checkin,
                    registrantType: registrant,
                    sessionName: session.name,
                    eventName: eventName,
                    onDismiss: {
                        showResultAlert = false
                        resultCheckin = nil
                    }
                )
            }
        }
        .sheet(item: $checkinError) { error in
            CheckinErrorView(
                title: error.title,
                message: error.message,
                onDismiss: {
                    checkinError = nil
                }
            )
        }
        .sheet(item: $selectedCheckin) { checkin in
            CheckinSuccessView(
                checkin: CheckinResponse(
                    id: checkin.id,
                    guest: checkin.guest,
                    eventSession: checkin.eventSession,
                    method: checkin.method,
                    latitude: checkin.latitude,
                    longitude: checkin.longitude,
                    createdAt: checkin.createdAt,
                    updatedAt: checkin.updatedAt
                ),
                registrantType: session.registrantTypes?.first(where: { 
                    $0.registrantType?.id == checkin.guest.registrantType?.id 
                }),
                sessionName: session.name,
                eventName: eventName,
                onDismiss: {
                    selectedCheckin = nil
                }
            )
        }
        .onAppear {
            loadSavedCategoryFilter()
            Task { await fetchCheckins() }
        }
    }
    
    private func loadSavedCategoryFilter() {
        let key = "categoryFilter_\(session.id)"
        if let savedData = UserDefaults.standard.data(forKey: key),
           let savedIds = try? JSONDecoder().decode([Int].self, from: savedData) {
            if savedIds.isEmpty {
                allCategoriesSelected = true
                selectedCategoryIds = Set(availableCategories.compactMap { $0.registrantType?.id })
            } else {
                selectedCategoryIds = Set(savedIds)
                allCategoriesSelected = selectedCategoryIds.count == availableCategories.count
            }
        } else {
            // Por defecto todas las categorías
            allCategoriesSelected = true
            selectedCategoryIds = Set(availableCategories.compactMap { $0.registrantType?.id })
        }
    }
    
    private func fetchCheckins() async {
        guard !isLoading else { return }
        
        guard let token = await getAuthToken() else {
            print("❌ No hay token disponible para fetchCheckins")
            return
        }
        
        isLoading = true
        
        let filter = "[{\"field\":\"e.event\",\"operator\":\"=\",\"value\":\(eventID)},{\"field\":\"e.eventSession\",\"operator\":\"=\",\"value\":\(session.id)}]"
        let encodedFilter = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(APIConstants.baseURL)checkins?page=1&query=&limit=100&order=id:DESC&filter=\(encodedFilter)"
        
        print("📡 Fetching checkins from endpoint: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL inválida: \(urlString)")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await NetworkManager.shared.dataRequest(for: request)
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ Checkins response: \(responseString)")
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("❌ Respuesta no es HTTPURLResponse")
                isLoading = false
                return
            }
            
            print("📊 Status code: \(http.statusCode)")
            
            if http.statusCode != 200 {
                print("❌ Status code no es 200")
                isLoading = false
                return
            }
            
            let result = try JSONDecoder().decode(CheckinsResponse.self, from: data)
            checkins = result.data
            print("✅ Checkins cargados: \(checkins.count)")
        } catch {
            print("❌ Error fetching checkins: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func log(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
    
    private func translateErrorMessage(_ message: String) -> String {
        let translations: [String: String] = [
            "Invalid data": "Datos inválidos",
            "invalid data": "Datos inválidos",
            "Not found": "No encontrado",
            "not found": "No encontrado",
            "Guest is not registered in this event": "El invitado no está registrado en este evento",
            "guest is not registered in this event": "El invitado no está registrado en este evento",
            "Guest is not registered in this session": "El invitado no está registrado en esta sesión",
            "guest is not registered in this session": "El invitado no está registrado en esta sesión",
            "Guest has already checked in for this session": "El invitado ya ha realizado check-in en esta sesión",
            "guest has already checked in for this session": "El invitado ya ha realizado check-in en esta sesión",
            "This ticket access category is not valid for this entry point": "Esta categoría de acceso no es válida para este punto de entrada",
            "this ticket access category is not valid for this entry point": "Esta categoría de acceso no es válida para este punto de entrada"
        ]
        
        // Buscar coincidencia exacta
        if let translated = translations[message] {
            return translated
        }
        
        // Buscar coincidencia parcial
        for (key, value) in translations {
            if message.lowercased().contains(key.lowercased()) {
                return value
            }
        }
        
        // Si no hay traducción conocida, mostrar mensaje desconocido
        return "Mensaje desconocido: \(message)"
    }
    
    private func registerCheckin(encryptedCode: String) async {
        guard let token = await getAuthToken() else {
            print("❌ No hay token disponible para registerCheckin")
            return
        }
        
        guard let url = URL(string: APIConstants.baseURL + "checkins/register") else {
            print("❌ URL inválida para checkins/register")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let categoryIdsArray = allCategoriesSelected ? [] : Array(selectedCategoryIds)
        let body: [String: Any] = [
            "event": eventID,
            "eventSession": session.id,
            "guest": encryptedCode,
            "registrantTypeIds": categoryIdsArray
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Log de la request
        print("📡 --- INICIO LOG REQUEST CHECKIN REGISTER ---")
        print("📡 URL: \(url.absoluteString)")
        print("📡 Method: \(request.httpMethod ?? "N/A")")
        print("📡 Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📡 Payload: \(bodyString)")
        } else {
            print("📡 Payload: (empty)")
        }
        print("📡 --- FIN LOG REQUEST CHECKIN REGISTER ---")
        
        do {
            let (data, response) = try await NetworkManager.shared.dataRequest(for: request)
            
            // Log de la respuesta
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ Response status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                print("✅ Response body: \(responseString)")
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("❌ Respuesta no es HTTPURLResponse")
                return
            }
            
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
            default:
                let apiError = try? decoder.decode(CheckinAPIErrorResponse.self, from: data)
                let rawErrorMessage = apiError?.message ?? apiError?.error ?? "Error desconocido"
                let translatedMessage = translateErrorMessage(rawErrorMessage)
                log("Status code: \(http.statusCode)")
                log("Raw error message: \(rawErrorMessage)")
                log("Translated message: \(translatedMessage)")
                await MainActor.run {
                    let finalMessage = translatedMessage.isEmpty ? "Error desconocido" : translatedMessage
                    log("Setting error with message: \(finalMessage)")
                    checkinError = CheckinError(
                        title: "Error de Check-in",
                        message: finalMessage
                    )
                }
            }
        } catch {
            log("Catch error: \(error.localizedDescription)")
            await MainActor.run {
                checkinError = CheckinError(
                    title: "Error de Check-in",
                    message: error.localizedDescription
                )
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
        // Parsear la fecha en formato yyyy-MM-dd
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "es_ES")
        
        guard let date = dateFormatter.date(from: startDate) else { return startDate }
        
        // Formatear la fecha como "dd MMM yyyy"
        let dateDisplay = DateFormatter()
        dateDisplay.dateFormat = "dd MMM yyyy"
        dateDisplay.locale = Locale(identifier: "es_ES")
        let formattedDate = dateDisplay.string(from: date)
        
        // Si hay hora, extraerla y mostrar (viene en formato HH:mm:ss)
        if let timeString = startTime, !timeString.isEmpty {
            // Extraer solo HH:mm del formato HH:mm:ss
            let timeComponents = timeString.split(separator: ":")
            if timeComponents.count >= 2 {
                let hour = timeComponents[0]
                let minute = timeComponents[1]
                return "\(formattedDate) a las \(hour):\(minute)"
            }
        }
        
        return formattedDate
    }
}

struct CheckinCard: View {
    let checkin: CheckinData
    let registrantType: SessionRegistrantType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Nombre del guest con badge de categoría
            HStack(spacing: 8) {
                Text(checkin.guest.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let accessType = checkin.guest.registrantType?.name {
                    Text(accessType)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandPrimary)
                        .cornerRadius(4)
                }
            }
            
            // Método y fecha/hora
            HStack(spacing: 12) {
                // Método
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
                
                // Fecha y hora
                if let createdAt = checkin.createdAt {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text(formatDateTime(createdAt))
                            .font(.caption)
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
    
    private func formatDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "dd MMM yyyy HH:mm"
        display.locale = Locale(identifier: "es_ES")
        return display.string(from: date)
    }
}

#Preview {
    CheckinsView(
        session: EventSession(id: 1, name: "Sesión Demo", description: nil, createdAt: nil, updatedAt: nil, isDefault: nil, startDate: "2026-03-01T00:00:00+00:00", startTime: nil, endDate: "2026-04-30T00:00:00+00:00", endTime: nil, registrantTypes: nil),
        eventID: 6,
        eventName: "Evento Demo"
    )
    .environmentObject(SessionManager())
}
