import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var consumptions: [Consumption]
    @Query private var activities: [Activity]
    @Query private var profiles: [UserProfile]

    @State private var showingAddConsumption = false
    @State private var showingAddActivity = false

    private var profile: UserProfile? {
        profiles.first
    }

    private var todayConsumptions: [Consumption] {
        consumptions
            .filter { $0.date.isSameDay(as: .now) }
            .sorted { $0.date > $1.date }
    }

    private var todayActivities: [Activity] {
        activities
            .filter { $0.date.isSameDay(as: .now) }
            .sorted { $0.date > $1.date }
    }

    private var caloriesEaten: Int {
        todayConsumptions.reduce(0) { $0 + $1.calories }
    }

    private var caloriesBurned: Int {
        todayActivities.reduce(0) { $0 + $1.caloriesBurned }
    }

    private var calorieGoal: Int {
        profile?.dailyCalorieGoal ?? 2000
    }

    private var netCalories: Int {
        caloriesEaten - caloriesBurned
    }

    private var caloriesRemaining: Int {
        calorieGoal - netCalories
    }

    private var consumedProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(max(Double(netCalories) / Double(calorieGoal), 0), 1)
    }

    private var mealSummaries: [(type: MealType, total: Int, count: Int)] {
        MealType.allCases.map { type in
            let items = todayConsumptions.filter { $0.type == type }
            return (
                type: type,
                total: items.reduce(0) { $0 + $1.calories },
                count: items.count
            )
        }
    }

    private var todayRecords: [TodayRecord] {
        let meals = todayConsumptions.map {
            TodayRecord(
                id: $0.id,
                title: $0.name,
                subtitle: "\($0.type.rawValue) • \($0.date.formatted(.dateTime.hour().minute()))",
                value: "+\($0.calories)",
                tint: .orange,
                symbolName: $0.type.symbolName,
                date: $0.date
            )
        }

        let workouts = todayActivities.map {
            TodayRecord(
                id: $0.id,
                title: $0.name,
                subtitle: "\($0.type.detailText(for: $0.inputValue)) • \($0.date.formatted(.dateTime.hour().minute()))",
                value: "-\($0.caloriesBurned)",
                tint: .blue,
                symbolName: $0.type.symbolName,
                date: $0.date
            )
        }

        return (meals + workouts).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    formulaCard
                    quickActionsCard
                    mealsCard
                    activitiesCard
                    timelineCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                ensureProfileExists()
                profile?.recalculateDailyCalorieGoal()
            }
            .onChange(of: profiles.count) { _, _ in
                ensureProfileExists()
            }
            .sheet(isPresented: $showingAddConsumption) {
                AddConsumptionView()
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Осталось \(caloriesRemaining) ккал")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(caloriesRemaining >= 0 ? .primary : .red)
                }

                Spacer()

                Image(systemName: caloriesRemaining >= 0 ? "target" : "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(caloriesRemaining >= 0 ? .blue : .red)
            }

            ProgressView(value: consumedProgress) {
                Text("Использовано \(netCalories) из \(calorieGoal)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .tint(caloriesRemaining >= 0 ? .blue : .red)

            Text(caloriesRemaining >= 0 ? "Дневной бюджет пока в норме." : "Ты уже превысил текущую дневную цель.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Формула дня")
                .font(.headline)

            HStack(spacing: 12) {
                BudgetMetricCard(title: "Цель", value: calorieGoal, symbolName: "target", tint: .green)
                BudgetMetricCard(title: "Еда", value: caloriesEaten, symbolName: "fork.knife", tint: .orange)
            }

            HStack(spacing: 12) {
                BudgetMetricCard(title: "Активность", value: caloriesBurned, symbolName: "figure.walk", tint: .blue)
                BudgetMetricCard(title: "Осталось", value: caloriesRemaining, symbolName: "equal.circle.fill", tint: caloriesRemaining >= 0 ? .primary : .red)
            }

            Text("Цель - еда + активность = остаток. Пользователь вносит только приемы пищи и параметры активности, расчет делается автоматически.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Быстрые действия")
                .font(.headline)

            HStack(spacing: 12) {
                DashboardActionButton(
                    title: "Добавить еду",
                    subtitle: "Записать прием пищи",
                    symbolName: "plus.circle.fill",
                    tint: .orange
                ) {
                    showingAddConsumption = true
                }

                DashboardActionButton(
                    title: "Добавить активность",
                    subtitle: "Шаги или минуты",
                    symbolName: "figure.walk.circle.fill",
                    tint: .blue
                ) {
                    showingAddActivity = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Приемы пищи")
                .font(.headline)

            ForEach(mealSummaries, id: \.type) { summary in
                SummaryRow(
                    title: summary.type.rawValue,
                    subtitle: summary.count == 0 ? "Сегодня пока пусто" : "\(summary.count) записей",
                    value: "\(summary.total) ккал",
                    symbolName: summary.type.symbolName,
                    tint: .orange
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var activitiesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Активность")
                .font(.headline)

            SummaryRow(
                title: "Сожжено сегодня",
                subtitle: todayActivities.isEmpty ? "Пока без записей" : "\(todayActivities.count) активностей",
                value: "\(caloriesBurned) ккал",
                symbolName: "flame.fill",
                tint: .blue
            )

            Text("Ходьба считается по шагам. Остальные активности считаются по минутам и весу из профиля.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Лента за сегодня")
                .font(.headline)

            if todayRecords.isEmpty {
                Text("Добавь еду или активность, и здесь появится понятная хронология дня.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayRecords) { item in
                    RecordRow(item: item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        let profile = UserProfile()
        modelContext.insert(profile)
    }
}

private struct TodayRecord: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let value: String
    let tint: Color
    let symbolName: String
    let date: Date
}

private struct BudgetMetricCard: View {
    let title: String
    let value: Int
    let symbolName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DashboardActionButton: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbolName)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryRow: View {
    let title: String
    let subtitle: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .frame(width: 28)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

private struct RecordRow: View {
    let item: TodayRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbolName)
                .frame(width: 30, height: 30)
                .foregroundStyle(item.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.value)
                .font(.headline)
                .foregroundStyle(item.tint)
        }
        .padding(14)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
