import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var viewModel = EventsViewModel()
    @State private var searchText = ""

    private var filteredEvents: [Event] {
        if searchText.isEmpty { return viewModel.events }
        return viewModel.events.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEvents) { event in
                            NavigationLink(destination: SessionsView(event: event)) {
                                EventCard(event: event)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .searchable(text: $searchText, prompt: "Buscar eventos")
            .navigationTitle("Eventos")
            .onAppear {
                Task {
                    await viewModel.refresh(token: session.token)
                }
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Contenedor de imagen con geometría fija para evitar que la imagen lo redimensione
            ZStack {
                // Placeholder que establece el fondo y el tamaño
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                // Imagen asíncrona que se superpone
                AsyncImage(url: event.coverImageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill() // Rellena el frame sin distorsionar
                    } else if phase.error != nil {
                        // En caso de error, muestra un ícono
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    } else {
                        // Mientras carga, muestra un spinner
                        ProgressView()
                    }
                }
            }
            .frame(height: 200) // Altura fija para el contenedor de la imagen
            .clipped() // Recorta cualquier contenido de la imagen que se salga del frame
            
            VStack(alignment: .leading, spacing: 12) {
                // Nombre del evento
                Text(event.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Fecha
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(event.eventDateRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Ubicación
                if let place = event.place {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                        Text(place)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Categorías
                if let categories = event.categories, !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories.prefix(3)) { category in
                                Text(category.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Fila de información
                HStack(spacing: 12) {
                    // Tipo de acceso
                    HStack(spacing: 4) {
                        Image(systemName: event.accessType == "ACCESS_TYPE_FREE" ? "ticket.fill" : "creditcard.fill")
                        Text(event.accessType == "ACCESS_TYPE_FREE" ? "Libre" : "Pago")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.accessType == "ACCESS_TYPE_FREE" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .foregroundColor(event.accessType == "ACCESS_TYPE_FREE" ? .green : .orange)
                    .cornerRadius(4)
                    
                    // Estado
                    HStack(spacing: 4) {
                        Image(systemName: event.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(event.isActive ? "Activo" : "Inactivo")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundColor(event.isActive ? .green : .gray)
                    .cornerRadius(4)
                    
                    // Registrados
                    if let count = event.registrantsCount {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                            Text("\(count)")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
            }
            .padding(12)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ChipView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct SessionsView: View {
    let event: Event
    @EnvironmentObject var session: SessionManager
    @State private var sessions: [EventSession] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header compacto con info del evento (sin imagen)
                VStack(alignment: .leading, spacing: 8) {
                    // Nombre del evento
                    HStack(spacing: 8) {
                        Text(event.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Información del evento: tipo acceso, estado y registrantes
                    HStack(spacing: 12) {
                        // Tipo de acceso
                        HStack(spacing: 4) {
                            Image(systemName: event.accessType == "ACCESS_TYPE_FREE" ? "ticket.fill" : "creditcard.fill")
                            Text(event.accessType == "ACCESS_TYPE_FREE" ? "Libre" : "Pago")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(event.accessType == "ACCESS_TYPE_FREE" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .foregroundColor(event.accessType == "ACCESS_TYPE_FREE" ? .green : .orange)
                        .cornerRadius(4)
                        
                        // Estado
                        HStack(spacing: 4) {
                            Image(systemName: event.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(event.isActive ? "Activo" : "Inactivo")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(event.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .foregroundColor(event.isActive ? .green : .gray)
                        .cornerRadius(4)
                        
                        // Registrados
                        if let count = event.registrantsCount {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                Text("\(count)")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                
                // Sesiones
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if sessions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No hay sesiones disponibles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(sessions) { item in
                                    NavigationLink(destination: CheckinsView(session: item, eventID: event.id)) {
                                        SessionCard(session: item, eventID: event.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                
                Spacer()
            }
        }
        .navigationTitle("Sesiones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await fetchSessions() }
        }
    }

    private func fetchSessions() async {
        guard let token = session.token, !isLoading else { return }
        isLoading = true
        let urlString = "\(APIConstants.baseURL)events/\(event.id)"
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
            let result = try JSONDecoder().decode(SessionsResponse.self, from: data)
            sessions = result.sessions
        } catch {
            print("Error fetching sessions: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

struct SessionCard: View {
    let session: EventSession
    let eventID: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Nombre de sesión
            HStack(spacing: 8) {
                Text(session.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Información de fecha en dos columnas
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
            
            Divider()
            
            // Tipos de registrante con barra de progreso
            if let registrantTypes = session.registrantTypes, !registrantTypes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(registrantTypes) { registrant in
                        VStack(alignment: .leading, spacing: 6) {
                            // Nombre y precio
                            HStack(spacing: 8) {
                                Text(registrant.registrantType.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                if registrant.price > 0 {
                                    Text("$\(registrant.price)")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                } else {
                                    Text("Libre")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                Text("\(registrant.available)/\(registrant.stock)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Barra de progreso
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: progressWidth(registrant), height: 6)
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .foregroundColor(.black)
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
    
    private func progressWidth(_ registrant: SessionRegistrantType) -> CGFloat {
        guard registrant.stock > 0 else { return 0 }
        let usedPercentage = CGFloat(registrant.used) / CGFloat(registrant.stock)
        return usedPercentage * 280
    }
}

#Preview {
    HomeView().environmentObject(SessionManager())
}
