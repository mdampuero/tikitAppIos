import SwiftUI

struct CheckinSuccessView: View {
    let checkin: CheckinResponse
    let registrantType: SessionRegistrantType?
    let sessionName: String
    let eventName: String
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con ícono de éxito
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding(.bottom, 12)
                
                Text("Check-in Exitoso")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Método y fecha/hora
                VStack(spacing: 4) {
                    Text("Método: \(checkin.method)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let createdAt = checkin.createdAt {
                        Text(formatDateTime(createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            
            // Detalles del invitado
            VStack(alignment: .leading, spacing: 20) {
                detailRow(icon: "person.fill", title: "Invitado", value: checkin.guest.fullName)
                detailRow(icon: "envelope.fill", title: "Email", value: checkin.guest.email)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            
            Divider()
            
            // Detalles del acceso
            VStack(alignment: .leading, spacing: 20) {
                detailRow(icon: "ticket.fill", title: "Tipo de Acceso", value: registrantType?.registrantType.name ?? "No especificado")
                detailRow(icon: "calendar", title: "Sesión", value: sessionName)
                detailRow(icon: "mappin.and.ellipse", title: "Evento", value: eventName)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            
            Spacer()
            
            // Botón para cerrar
            Button(action: {
                onDismiss?()
            }) {
                Text("Cerrar")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
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

#if DEBUG
struct CheckinSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        let guest = CheckinResponse.Guest(id: 1, firstName: "John", lastName: "Doe", email: "john.doe@example.com")
        let sessionInfo = CheckinResponse.EventSessionInfo(id: 1, name: "Sesión Principal")
        let checkin = CheckinResponse(id: 1, guest: guest, eventSession: sessionInfo, method: "QR", latitude: nil, longitude: nil, createdAt: nil, updatedAt: nil)
        let registrantType = SessionRegistrantType(id: 1, registrantType: RegistrantType(id: 1, name: "Acceso General", price: 0), price: 0, stock: 100, used: 10, available: 90, isActive: true)
        
        CheckinSuccessView(
            checkin: checkin,
            registrantType: registrantType,
            sessionName: "Apertura Conferencia",
            eventName: "Tech Summit 2026"
        )
    }
}
#endif
