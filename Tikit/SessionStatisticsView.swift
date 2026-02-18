import SwiftUI

struct SessionStatisticsView: View {
    let session: EventSession
    let eventName: String
    let totalCheckins: Int
    let totalRegistered: Int
    let temporarySessionData: TemporarySessionData?
    
    @Environment(\.dismiss) var dismiss
    @State private var updatedSessionData: TemporarySessionData?
    @State private var isRefreshing = false
    
    private var registrantTypes: [SessionRegistrantType] {
        // Usar datos actualizados si están disponibles, si no usar los originales
        if let updated = updatedSessionData {
            return updated.registrantTypes.filter { $0.isActive }
        }
        return session.registrantTypes?.filter { $0.isActive } ?? []
    }
    
    private var currentTotalRegistered: Int {
        updatedSessionData?.totalRegistered ?? totalRegistered
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header con información general
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 44))
                            .foregroundColor(.brandPrimary)
                        
                        Text("Estadísticas de la Sesión")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(eventName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(session.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Información general de check-ins
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Check-ins realizados")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(totalCheckins)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.brandPrimary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Registrados totales")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(totalRegistered)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.brandSecondary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Barra de progreso general
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Asistencia General")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(attendancePercentage)%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.tertiarySystemBackground))
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.brandPrimary, .brandSecondary]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(attendancePercentage) / 100)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Desglose por categoría
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Asistencia por Categoría de Acceso")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if registrantTypes.isEmpty {
                            Text("Sin categorías disponibles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(registrantTypes, id: \.id) { registrantType in
                                    CategoryStatsRow(registrantType: registrantType)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Información de tiempo si es sesión temporal
                    if let tempData = temporarySessionData {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text("Información de sesión temporal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Inicio de sesión")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDateTime(tempData.sessionStartTime))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Expiración")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDateTime(tempData.expirationDate))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                refreshSessionDataSilently()
            }
        }
    }
    
    private var attendancePercentage: Int {
        guard currentTotalRegistered > 0 else { return 0 }
        return Int(Double(totalCheckins) / Double(currentTotalRegistered) * 100)
    }
    
    private func refreshSessionDataSilently() {
        guard temporarySessionData != nil else { return }
        
        isRefreshing = true
        Task {
            let updated = await SessionCodeManager.shared.refreshSessionDataSilently()
            self.updatedSessionData = updated
            isRefreshing = false
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - Fila de estadística por categoría
struct CategoryStatsRow: View {
    let registrantType: SessionRegistrantType
    
    private var categoryName: String {
        registrantType.registrantType?.name ?? "Categoría \(registrantType.id)"
    }
    
    private var registered: Int {
        registrantType.registered ?? 0
    }
    
    private var checkins: Int {
        registrantType.checkins ?? 0
    }
    
    private var attendancePercentage: Int {
        guard registered > 0 else { return 0 }
        return Int(Double(checkins) / Double(registered) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(checkins)/\(registered) asistieron")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(attendancePercentage)%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemBackground))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.brandPrimary, .brandSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(attendancePercentage) / 100)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
}
