import Foundation

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    private var currentPage = 1
    private var totalPages = 1
    private var isFetching = false

    func loadMoreIfNeeded(currentItem item: Event?, token: String?) async {
        guard let token = token, !isFetching else { return }
        guard currentPage <= totalPages else { return }
        if item == nil || item == events.last {
            isFetching = true
            await fetchEvents(token: token)
            isFetching = false
        }
    }

    func refresh(token: String?) async {
        guard let token = token else { return }
        currentPage = 1
        totalPages = 1
        events = []
        isFetching = false
        await fetchEvents(token: token)
    }

    private func fetchEvents(token: String) async {
        guard !isLoading, currentPage <= totalPages else { return }
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "\(APIConstants.baseURL)events?page=\(currentPage)&query=&order=startDate:ASC&isActive=true&limit=100&order=id:DESC&filter=[]"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                // print("Error: Status code \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }
            
            let result = try JSONDecoder().decode(EventsResponse.self, from: data)
            events.append(contentsOf: result.data)
            currentPage += 1
            totalPages = result.pagination.totalPages
            
            // print("✓ Loaded page \(currentPage - 1) of \(totalPages) - Total events: \(events.count)")
        } catch is CancellationError {
            // print("Cancelled request (expected when navigating)")
        } catch {
            // print("Error fetching events: \(error.localizedDescription)")
        }
    }
}
