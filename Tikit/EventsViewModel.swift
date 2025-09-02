import Foundation

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    private var currentPage = 1
    private var totalPages = 1

    func loadMoreIfNeeded(currentItem item: Event?, session: SessionManager) async {
        if item == nil || item == events.last {
            await fetchEvents(session: session)
        }
    }

    private func fetchEvents(session: SessionManager) async {
        guard !isLoading, currentPage <= totalPages, let token = session.token else { return }
        isLoading = true
        let urlString = "https://tikit.cl/api/events?page=\(currentPage)&query=&limit=10&order=id:DESC&filter=[]"
        guard let url = URL(string: urlString) else { isLoading = false; return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                isLoading = false
                return
            }
            if http.statusCode == 401 {
                isLoading = false
                if await session.refreshAuthToken() {
                    await fetchEvents(session: session)
                }
                return
            }
            guard http.statusCode == 200 else {
                isLoading = false
                return
            }
            let result = try JSONDecoder().decode(EventsResponse.self, from: data)
            events.append(contentsOf: result.data)
            currentPage += 1
            totalPages = result.pagination.totalPages
        } catch {
            // handle error if necessary
            isLoading = false
            return
        }
        isLoading = false
    }
}
