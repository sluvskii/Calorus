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
                                Text(item.date, style: .date).font(.caption).foregroundColor(.secondary)
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
                                Text(item.type.rawValue).font(.headline)
                                Text("\(item.durationMinutes) мин • \(item.date, style: .date)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("-\(item.caloriesBurned)").fontWeight(.bold).foregroundColor(.orange)
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
    
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var isMale: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Физические параметры")) {
                    HStack {
                        Text("Вес (кг)")
                        Spacer()
                        TextField("70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Рост (см)")
                        Spacer()
                        TextField("170", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Возраст")
                        Spacer()
                        TextField("30", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Пол", selection: $isMale) {
                        Text("Мужской").tag(true)
                        Text("Женский").tag(false)
                    }
                }
                
                Section {
                    Button("Сохранить параметры") {
                        updateProfile()
                    }
                }
                
                if let profile = profiles.first {
                    Section(header: Text("Расчетная норма")) {
                        HStack {
                            Text("Ваша цель")
                            Spacer()
                            Text("\(profile.dailyCalorieGoal) ккал")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
            .onAppear {
                if let profile = profiles.first {
                    weight = String(format: "%.1f", profile.weight)
                    height = String(format: "%.1f", profile.height)
                    age = "\(profile.age)"
                    isMale = profile.isMale
                }
            }
        }
    }
    
    private func updateProfile() {
        let w = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 70.0
        let h = Double(height.replacingOccurrences(of: ",", with: ".")) ?? 170.0
        let a = Int(age) ?? 30
        
        if let profile = profiles.first {
            profile.weight = w
            profile.height = h
            profile.age = a
            profile.isMale = isMale
        } else {
            let profile = UserProfile(weight: w, height: h, age: a, isMale: isMale)
            modelContext.insert(profile)
        }
        try? modelContext.save()
    }
}
