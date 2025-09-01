import SwiftUI

struct ScanView: View {
    let session: EventSession

    var body: some View {
        Text("Scan for session: \(session.name)")
            .navigationTitle("Escanear")
    }
}

#Preview {
    ScanView(session: EventSession(id: 0, name: "Demo", description: nil, createdAt: nil, updatedAt: nil, isDefault: nil, startDate: nil, startTime: nil, endDate: nil, endTime: nil))
}
