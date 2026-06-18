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
                Section("Детали") {
                    TextField("Название (напр. Яблоко)", text: $name)
                    TextField("Калории", text: $calories)
                        .keyboardType(.numberPad)

                    Picker("Тип", selection: $selectedType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section {
                    Text("Для еды пока используется ручной ввод калорий, но все дневные суммы, остаток и прогресс приложение считает автоматически.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Добавить еду")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled(trimmedName.isEmpty || parsedCalories == nil)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedCalories: Int? {
        Int(calories)
    }

    private func save() {
        guard let cal = parsedCalories else { return }
        let item = Consumption(name: trimmedName, calories: cal, type: selectedType)
        modelContext.insert(item)
        dismiss()
    }
}

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var profiles: [UserProfile]

    @State private var selectedType: ActivityType = .walking
    @State private var inputValue: String = ""

    private var profile: UserProfile? {
        profiles.first
    }

    private var parsedInputValue: Double? {
        Double(inputValue.replacingOccurrences(of: ",", with: "."))
    }

    private var weightKg: Double {
        profile?.weightKg ?? 70
    }

    private var estimatedCalories: Int {
        selectedType.estimateCalories(inputValue: parsedInputValue ?? 0, weightKg: weightKg)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Активность") {
                    Picker("Тип", selection: $selectedType) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    TextField(selectedType.inputPlaceholder, text: $inputValue)
                        .keyboardType(.numberPad)
                    LabeledContent(selectedType.inputTitle, value: selectedType.inputKind == .steps ? "шаги" : "минуты")
                }

                Section("Расчет") {
                    LabeledContent("Вес из профиля", value: "\(Int(weightKg)) кг")
                    LabeledContent("Сожжено", value: "\(estimatedCalories) ккал")
                }

                Section {
                    Text("Пользователь вводит только шаги или длительность активности. Калории рассчитываются автоматически по типу нагрузки и весу из профиля.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Добавить активность")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled((parsedInputValue ?? 0) <= 0)
                }
            }
        }
    }

    private func save() {
        guard let value = parsedInputValue, value > 0 else { return }
        let item = Activity(
            type: selectedType,
            inputValue: value,
            caloriesBurned: selectedType.estimateCalories(inputValue: value, weightKg: weightKg)
        )
        modelContext.insert(item)
        dismiss()
    }
}
