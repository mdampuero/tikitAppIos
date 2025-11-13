import Foundation

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    private var currentPage = 1
    private var totalPages = 1

    func loadMoreIfNeeded(currentItem item: Event?, token: String?) async {
        guard let token = token else { return }
        if item == nil || item == events.last {
            await fetchEvents(token: token)
        }
    }

    func refresh(token: String?) async {
        guard let token = token else { return }
        currentPage = 1
        totalPages = 1
        events = []
        await fetchEvents(token: token)
    }

    private func fetchEvents(token: String) async {
        guard !isLoading, currentPage <= totalPages else { return }
        isLoading = true
        let urlString = "\(APIConstants.baseURL)events?page=\(currentPage)&query=&limit=10&order=id:DESC&filter=[]"
        guard let url = URL(string: urlString) else { isLoading = false; return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("fetchEvents response: \(jsonString)")
            }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                isLoading = false
                return
            }
            let result = try JSONDecoder().decode(EventsResponse.self, from: data)
            events.append(contentsOf: result.data)
            currentPage += 1
            totalPages = result.pagination.totalPages
        } catch {
            // handle error if necessary
        }
        isLoading = false
    }
}
