import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @StateObject private var viewModel = EventsViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.events) { event in
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

#Preview {
    HomeView().environmentObject(SessionManager())
}
