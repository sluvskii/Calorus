import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var consumptions: [Consumption]
    @Query private var activities: [Activity]
    @Query private var profiles: [UserProfile]
    
    @State private var showingAddConsumption = false
    @State private var showingAddActivity = false
    
    private var todayConsumptions: [Consumption] {
        let today = Date().startOfDay
        return consumptions.filter { $0.date >= today }
    }
    
    private var todayActivities: [Activity] {
        let today = Date().startOfDay
        return activities.filter { $0.date >= today }
    }
    
    private var caloriesEaten: Int {
        todayConsumptions.reduce(0) { $0 + $1.calories }
    }
    
    private var caloriesBurned: Int {
        todayActivities.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    private var calorieGoal: Int {
        profiles.first?.dailyCalorieGoal ?? 2000
    }
    
    private var caloriesRemaining: Int {
        calorieGoal - caloriesEaten + caloriesBurned
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Main Summary
                    VStack(spacing: 8) {
                        Text("Осталось")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text("\(caloriesRemaining)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(caloriesRemaining >= 0 ? .primary : .red)
                        
                        Text("ккал")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Stats Row
                    HStack(spacing: 40) {
                        StatItem(title: "Съедено", value: caloriesEaten, icon: "fork.knife")
                        StatItem(title: "Сожжено", value: caloriesBurned, icon: "flame.fill")
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(title: "Еда", icon: "plus", color: .primary) {
                            showingAddConsumption = true
                        }
                        
                        ActionButton(title: "Активность", icon: "figure.walk", color: .primary) {
                            showingAddActivity = true
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Recent Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Сегодня")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 24)
                        
                        if todayConsumptions.isEmpty && todayActivities.isEmpty {
                            Text("Пока нет записей")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(todayConsumptions.sorted(by: { $0.date > $1.date })) { item in
                                    RecordRow(title: item.name, subtitle: item.type.rawValue, value: "+\(item.calories)", isPositive: true)
                                }
                                ForEach(todayActivities.sorted(by: { $0.date > $1.date })) { item in
                                    RecordRow(title: item.name, subtitle: "Тренировка", value: "-\(item.caloriesBurned)", isPositive: false)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 100) // Padding for tab bar
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if profiles.isEmpty {
                    modelContext.insert(UserProfile())
                }
            }
            .sheet(isPresented: $showingAddConsumption) {
                AddConsumptionView()
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.callout)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemBackground))
            .foregroundColor(color)
            .cornerRadius(16)
        }
    }
}

struct RecordRow: View {
    let title: String
    let subtitle: String
    let value: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(isPositive ? .primary : .secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
