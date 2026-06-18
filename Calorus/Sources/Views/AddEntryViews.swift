import SwiftUI
import SwiftData

struct AddConsumptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var selectedType: MealType = .lunch
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Детали")) {
                    TextField("Название (напр. Яблоко)", text: $name)
                    TextField("Калории", text: $calories)
                        .keyboardType(.numberPad)
                    
                    Picker("Тип", selection: $selectedType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Добавить еду")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled(name.isEmpty || calories.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        guard let cal = Int(calories) else { return }
        let item = Consumption(name: name, calories: cal, type: selectedType)
        modelContext.insert(item)
        dismiss()
    }
}

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var calories: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Детали")) {
                    TextField("Активность (напр. Бег)", text: $name)
                    TextField("Сожжено калорий", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Добавить активность")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled(name.isEmpty || calories.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        guard let cal = Int(calories) else { return }
        let item = Activity(name: name, caloriesBurned: cal)
        modelContext.insert(item)
        dismiss()
    }
}
