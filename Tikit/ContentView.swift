import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionManager
    @State private var temporarySession: TemporarySessionData?
    @State private var viewId = UUID()
    
    var body: some View {
        Group {
            if let tempSession = temporarySession {
                // Ir directamente a CheckinsView con la sesión temporal
                TemporarySessionCheckinView(sessionData: tempSession)
                    .id(viewId)
            } else if session.isLoggedIn {
                // Mostrar vista principal con login normal
                MainView()
            } else {
                // Mostrar login
                LoginView()
            }
        }
        .onAppear {
            checkTemporarySession()
        }
        .onChange(of: session.isLoggedIn) { _ in
            checkTemporarySession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionCodeValidated)) { _ in
            // Agregar un pequeño delay para asegurar que los datos estén guardados
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkTemporarySession()
                viewId = UUID() // Forzar recreación completa
            }
        }
    }
    
    private func checkTemporarySession() {
        // Verificar si hay una sesión temporal válida
        temporarySession = SessionCodeManager.shared.getTemporarySession()
    }
}

// MARK: - Wrapper para CheckinsView con sesión temporal
struct TemporarySessionCheckinView: View {
    let sessionData: TemporarySessionData
    @State private var shouldDismiss = false
    @State private var isReady = false
    
    var body: some View {
        if shouldDismiss {
            LoginView()
        } else {
            NavigationView {
                CheckinsView(
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
                        registrantTypes: nil
                    ),
                    eventID: sessionData.eventId,
                    eventName: sessionData.eventName,
                    onLogout: {
                        SessionCodeManager.shared.clearTemporarySession()
                        shouldDismiss = true
                    }
                )
                .navigationBarBackButtonHidden(true)
                .opacity(isReady ? 1 : 0)
            }
            .navigationViewStyle(.stack)
            .onAppear {
                // Forzar redibujado después de un momento para ajustar el safe area
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        isReady = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(SessionManager())
}

extension Notification.Name {
    static let sessionCodeValidated = Notification.Name("sessionCodeValidated")
}
