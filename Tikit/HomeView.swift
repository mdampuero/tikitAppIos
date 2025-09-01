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
            List {
                ForEach(filteredEvents) { event in
                    NavigationLink(destination: SessionsView(event: event)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.name)
                                .font(.headline)
                            HStack {
                                ChipView(text: event.accessType == "ACCESS_TYPE_FREE" ? "Entrada libre" : "Evento pago",
                                         color: event.accessType == "ACCESS_TYPE_FREE" ? .green : .red)
                                ChipView(text: event.isActive ? "SI" : "NO",
                                         color: event.isActive ? .green : .red)
                            }
                            Text("Creado: \(event.createdDateFormatted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentItem: event, token: session.token)
                        }
                    }
                }
                if viewModel.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
            .navigationTitle("Eventos")
            .onAppear {
                Task {
                    await viewModel.loadMoreIfNeeded(currentItem: nil, token: session.token)
                }
            }
        }
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
        List(sessions) { item in
            VStack(alignment: .leading) {
                Text("Inicio: \(item.startDateFormatted)")
                Text("Fin: \(item.endDateFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Sesiones")
        .onAppear {
            Task { await fetchSessions() }
        }
    }

    private func fetchSessions() async {
        guard let token = session.token, !isLoading else { return }
        isLoading = true
        let urlString = "https://tikit.cl/api/events/\(event.id)"
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
            let result = try JSONDecoder().decode(EventDetailResponse.self, from: data)
            sessions = result.data.sessions
        } catch {
            // handle error if needed
        }
        isLoading = false
    }
}

#Preview {
    HomeView().environmentObject(SessionManager())
}
