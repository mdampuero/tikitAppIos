import SwiftUI

struct CheckinErrorView: View {
    let title: String
    let message: String
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con ícono de error
            VStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.bottom, 12)
                
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            
            // Mensaje de error
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.isEmpty ? "Ha ocurrido un error" : message)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
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
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
    }
}

#if DEBUG
struct CheckinErrorView_Previews: PreviewProvider {
    static var previews: some View {
        CheckinErrorView(
            title: "Error de Check-in",
            message: "Esta persona ya realizó check-in en esta sesión."
        )
    }
}
#endif
