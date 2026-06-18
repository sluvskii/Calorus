import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Consumption.date, order: .reverse) private var consumptions: [Consumption]
    @Query(sort: \Activity.date, order: .reverse) private var activities: [Activity]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Приемы пищи")) {
                    ForEach(consumptions) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                Text("\(item.type.rawValue) • \(item.date.formatted(.dateTime.day().month().hour().minute()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("+\(item.calories)").fontWeight(.bold)
                        }
                    }
                }
                
                Section(header: Text("Тренировки")) {
                    ForEach(activities) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                Text("\(item.type.detailText(for: item.inputValue)) • \(item.date.formatted(.dateTime.day().month().hour().minute()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("-\(item.caloriesBurned)").fontWeight(.bold).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("История")
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var age: String = ""
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var sex: BiologicalSex = .male
    @State private var lifestyle: LifestyleActivityLevel = .light
    @State private var goalPreference: GoalPreference = .maintain

    private var profile: UserProfile? {
        profiles.first
    }

    private var parsedAge: Int? {
        Int(age)
    }

    private var parsedHeight: Double? {
        Double(heightCm.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedWeight: Double? {
        Double(weightKg.replacingOccurrences(of: ",", with: "."))
    }

    private var calculatedGoalPreview: Int {
        let previewProfile = UserProfile(
            weightKg: parsedWeight ?? 70,
            heightCm: parsedHeight ?? 175,
            age: parsedAge ?? 30,
            sex: sex,
            lifestyle: lifestyle,
            goalPreference: goalPreference
        )
        return previewProfile.dailyCalorieGoal
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    Picker("Пол", selection: $sex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    TextField("Возраст", text: $age)
                        .keyboardType(.numberPad)

                    TextField("Рост, см", text: $heightCm)
                        .keyboardType(.numberPad)

                    TextField("Вес, кг", text: $weightKg)
                        .keyboardType(.decimalPad)
                }

                Section("Образ жизни") {
                    Picker("Уровень активности", selection: $lifestyle) {
                        ForEach(LifestyleActivityLevel.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    Text(lifestyle.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Цель") {
                    Picker("Режим", selection: $goalPreference) {
                        ForEach(GoalPreference.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section("Результат") {
                    LabeledContent("Дневная норма", value: "\(calculatedGoalPreview) ккал")
                    Text("Цель рассчитывается автоматически по полу, возрасту, росту, весу и уровню повседневной активности.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Сохранить профиль") {
                        updateProfile()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Настройки")
            .onAppear {
                ensureProfileExists()
                loadProfile()
            }
        }
    }

    private var isFormValid: Bool {
        guard let age = parsedAge, let height = parsedHeight, let weight = parsedWeight else {
            return false
        }

        return age >= 14 && height >= 130 && weight >= 35
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile())
    }

    private func loadProfile() {
        guard let profile else { return }
        age = "\(profile.age)"
        heightCm = "\(Int(profile.heightCm))"
        weightKg = "\(Int(profile.weightKg))"
        sex = profile.sex
        lifestyle = profile.lifestyle
        goalPreference = profile.goalPreference
    }

    private func updateProfile() {
        guard
            let age = parsedAge,
            let height = parsedHeight,
            let weight = parsedWeight
        else {
            return
        }

        if let profile = profiles.first {
            profile.age = age
            profile.heightCm = height
            profile.weightKg = weight
            profile.sex = sex
            profile.lifestyle = lifestyle
            profile.goalPreference = goalPreference
            profile.recalculateDailyCalorieGoal()
        } else {
            let profile = UserProfile(
                weightKg: weight,
                heightCm: height,
                age: age,
                sex: sex,
                lifestyle: lifestyle,
                goalPreference: goalPreference
            )
            modelContext.insert(profile)
        }

        try? modelContext.save()
        loadProfile()
    }
}
