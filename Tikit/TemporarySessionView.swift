import SwiftUI

struct TemporarySessionView: View {
    let sessionData: TemporarySessionData
    @State private var showLogoutAlert = false
    @State private var sessionClosed = false
    
    var body: some View {
        if sessionClosed {
            // Regresar al login
            LoginView()
        } else {
            navigationContent
        }
    }
    
    private var navigationContent: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header con información de la sesión
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(.brandPrimary)
                    
                    Text("Sesión Temporal Activa")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(sessionData.sessionName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(sessionData.eventName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Información de tiempo
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.brandPrimary)
                        Text("Fecha de sesión:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(formatDate(sessionData.startDate))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.orange)
                        Text("Sesión expira:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(formatDateTime(sessionData.expirationDate))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Botón para ir a check-ins
                NavigationLink(destination: CheckinsView(
                    session: EventSession(
                        id: sessionData.sessionId,
                        name: sessionData.sessionName,
                        description: nil,
                        createdAt: nil,
                        updatedAt: nil,
                        isDefault: nil,
                        startDate: sessionData.startDate,
                        startTime: sessionData.startTime,
                        endDate: sessionData.endDate,
                        endTime: sessionData.endTime,
                        registrantTypes: sessionData.registrantTypes
                    ),
                    eventID: sessionData.eventId,
                    eventName: sessionData.eventName,
                    totalRegistered: sessionData.totalRegistered
                )) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Ir a Check-ins")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandPrimary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Botón de cerrar sesión
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar sesión temporal")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Sesión Temporal")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Cerrar sesión", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) {
                SessionCodeManager.shared.clearTemporarySession()
                sessionClosed = true
            }
        } message: {
            Text("¿Está seguro que desea cerrar la sesión temporal? Deberá escanear un nuevo código para acceder nuevamente.")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "es_ES")
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy"
        displayFormatter.locale = Locale(identifier: "es_ES")
        
        return displayFormatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}
