import SwiftUI

struct CategoryFilterView: View {
    let categories: [SessionRegistrantType]
    @Binding var selectedCategoryIds: Set<Int>
    @Binding var allCategoriesSelected: Bool
    let sessionId: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var localSelectedIds: Set<Int> = []
    @State private var localAllSelected: Bool = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Explicación
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selecciona las categorías de acceso que deseas permitir para realizar check-in en esta sesión.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                }
                
                // Lista de categorías
                List {
                    // Opción "Todas las categorías"
                    Button(action: {
                        toggleAllCategories()
                    }) {
                        HStack {
                            Image(systemName: localAllSelected ? "checkmark.square.fill" : "square")
                                .foregroundColor(localAllSelected ? .brandPrimary : .gray)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Todas las categorías")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Permitir check-in para todos los tipos de acceso")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color(.systemBackground))
                    
                    // Categorías individuales
                    ForEach(categories) { category in
                        if let registrantType = category.registrantType {
                            Button(action: {
                                toggleCategory(id: registrantType.id)
                            }) {
                                HStack {
                                    Image(systemName: localSelectedIds.contains(registrantType.id) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(localSelectedIds.contains(registrantType.id) ? .brandPrimary : .gray)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(registrantType.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        if let checkins = category.checkins {
                                            Text("\(checkins) check-ins")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Indicador de precio
                                    if category.price > 0 {
                                        Text("$\(category.price)")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .foregroundColor(.orange)
                                            .cornerRadius(4)
                                    } else {
                                        Text("Gratis")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(4)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .listRowBackground(Color(.systemBackground))
                        }
                    }
                }
                .listStyle(.plain)
                
                // Botones de acción
                HStack(spacing: 12) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    
                    Button("Guardar") {
                        saveAndDismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(localSelectedIds.isEmpty ? Color.gray : Color.brandPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(localSelectedIds.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Filtrar Categorías")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            localSelectedIds = selectedCategoryIds
            localAllSelected = allCategoriesSelected
        }
    }
    
    private func toggleAllCategories() {
        localAllSelected.toggle()
        if localAllSelected {
            localSelectedIds = Set(categories.compactMap { $0.registrantType?.id })
        }
    }
    
    private func toggleCategory(id: Int) {
        if localSelectedIds.contains(id) {
            localSelectedIds.remove(id)
        } else {
            localSelectedIds.insert(id)
        }
        
        // Actualizar estado de "todas las categorías"
        localAllSelected = localSelectedIds.count == categories.count
    }
    
    private func saveAndDismiss() {
        // Guardar en UserDefaults
        let key = "categoryFilter_\(sessionId)"
        let idsArray = localAllSelected ? [] : Array(localSelectedIds)
        
        if let encoded = try? JSONEncoder().encode(idsArray) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
        
        // Actualizar bindings
        selectedCategoryIds = localSelectedIds
        allCategoriesSelected = localAllSelected
        
        dismiss()
    }
}

#Preview {
    CategoryFilterView(
        categories: [
            SessionRegistrantType(
                id: 1,
                registrantType: RegistrantType(id: 1, name: "General", price: 0),
                price: 0,
                stock: 100,
                used: 50,
                available: 50,
                isActive: true,
                registered: 80,
                checkins: 60,
                attendancePercentage: 75.0
            ),
            SessionRegistrantType(
                id: 2,
                registrantType: RegistrantType(id: 2, name: "VIP", price: 5000),
                price: 5000,
                stock: 50,
                used: 30,
                available: 20,
                isActive: true,
                registered: 40,
                checkins: 30,
                attendancePercentage: 75.0
            )
        ],
        selectedCategoryIds: .constant([1, 2]),
        allCategoriesSelected: .constant(true),
        sessionId: 1
    )
}
