import SwiftUI

struct ToastMessage: Equatable {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case error
        case success
        case warning
        case info
    }
}

struct ToastView: View {
    let toast: ToastMessage
    
    var backgroundColor: Color {
        switch toast.type {
        case .error:
            return Color.red
        case .success:
            return Color.green
        case .warning:
            return Color.orange
        case .info:
            return Color.blue
        }
    }
    
    var systemImage: String {
        switch toast.type {
        case .error:
            return "xmark.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.white)
            
            Text(toast.message)
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastView(toast: ToastMessage(message: "Error: No hay conexión", type: .error))
        ToastView(toast: ToastMessage(message: "Operación exitosa", type: .success))
        ToastView(toast: ToastMessage(message: "Advertencia importante", type: .warning))
        ToastView(toast: ToastMessage(message: "Información", type: .info))
    }
    .padding()
}
