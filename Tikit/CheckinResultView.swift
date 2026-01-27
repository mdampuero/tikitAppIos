import SwiftUI

enum CheckinResultType {
    case success(CheckinResponse)
    case failure(String)
}

struct CheckinResultView: View {
    let result: CheckinResultType
    @Binding var isPresented: Bool

    private var backgroundColor: Color {
        switch result {
        case .success:
            return Color.green.opacity(0.8)
        case .failure:
            return Color.red.opacity(0.8)
        }
    }

    private var iconName: String {
        switch result {
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }

    private var title: String {
        switch result {
        case .success:
            return "Check-in Exitoso"
        case .failure:
            return "Error en Check-in"
        }
    }

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Image(systemName: iconName)
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                switch result {
                case .success(let checkin):
                    successDetails(for: checkin)
                case .failure(let message):
                    failureDetails(for: message)
                }

                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            
            // Botón de cerrar
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private func successDetails(for checkin: CheckinResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow(title: "Nombre", value: checkin.guest.fullName)
            detailRow(title: "Email", value: checkin.guest.email)
            detailRow(title: "Sesión", value: checkin.eventSession.name)
            detailRow(title: "Método", value: checkin.method)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func failureDetails(for message: String) -> some View {
        Text(Translations.translate(message))
            .font(.headline)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}
