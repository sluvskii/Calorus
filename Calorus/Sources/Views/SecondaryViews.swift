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
                                Text(item.name).font(.headline)
                                Text(item.date, style: .date).font(.caption).foregroundColor(.secondary)
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
    
    @State private var dailyGoal: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Цель")) {
                    HStack {
                        Text("Ккал в день")
                        Spacer()
                        TextField("2000", text: $dailyGoal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                updateGoal()
                            }
                    }
                }
                
                Section {
                    Button("Сохранить цель") {
                        updateGoal()
                    }
                }
            }
            .navigationTitle("Настройки")
            .onAppear {
                if let profile = profiles.first {
                    dailyGoal = "\(profile.dailyCalorieGoal)"
                }
            }
        }
    }
    
    private func updateGoal() {
        guard let goal = Int(dailyGoal) else { return }
        if let profile = profiles.first {
            profile.dailyCalorieGoal = goal
        } else {
            let profile = UserProfile(dailyCalorieGoal: goal)
            modelContext.insert(profile)
        }
        try? modelContext.save()
    }
}
