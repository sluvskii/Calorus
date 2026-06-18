import SwiftUI
import SwiftData

struct AddConsumptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var inputMode: InputMode = .direct
    
    // Direct mode
    @State private var totalCalories: String = ""
    
    // Calculate mode
    @State private var grams: String = ""
    @State private var caloriesPer100g: String = ""
    
    @State private var selectedType: MealType = .lunch
    
    enum InputMode: String, CaseIterable {
        case direct = "Готовые калории"
        case calculate = "Рассчитать по весу"
    }
    
    private var calculatedCalories: Int {
        if inputMode == .direct {
            return Int(totalCalories) ?? 0
        } else {
            let w = Double(grams) ?? 0
            let c = Double(caloriesPer100g) ?? 0
            return Int((w * c) / 100.0)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название (напр. Яблоко)", text: $name)
                    Picker("Тип приема", selection: $selectedType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Ввод калорий")) {
                    Picker("Способ ввода", selection: $inputMode) {
                        ForEach(InputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if inputMode == .direct {
                        TextField("Калории (ккал)", text: $totalCalories)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Вес (граммы)", text: $grams)
                            .keyboardType(.numberPad)
                        TextField("Калорийность (на 100г)", text: $caloriesPer100g)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    HStack {
                        Text("Итого калорий:")
                        Spacer()
                        Text("\(calculatedCalories) ккал")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
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
                    .disabled(name.isEmpty || calculatedCalories == 0)
                }
            }
        }
    }
    
    private func save() {
        guard calculatedCalories > 0 else { return }
        let item = Consumption(name: name, calories: calculatedCalories, type: selectedType)
        modelContext.insert(item)
        dismiss()
    }
}

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    
    @State private var selectedType: ActivityType = .walking
    @State private var durationMinutes: String = ""
    
    private var calculatedBurn: Int {
        guard let duration = Double(durationMinutes), duration > 0 else { return 0 }
        let weight = profiles.first?.weight ?? 70.0
        let burnPerMin = selectedType.caloriesPerMinute(weight: weight)
        return Int(burnPerMin * duration)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Параметры активности")) {
                    Picker("Тип", selection: $selectedType) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Длительность (минут)", text: $durationMinutes)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    HStack {
                        Text("Сожжено:")
                        Spacer()
                        Text("\(calculatedBurn) ккал")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Новая активность")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled(calculatedBurn == 0)
                }
            }
        }
    }
    
    private func save() {
        guard let duration = Int(durationMinutes), calculatedBurn > 0 else { return }
        let item = Activity(type: selectedType, durationMinutes: duration, caloriesBurned: calculatedBurn)
        modelContext.insert(item)
        dismiss()
    }
}
