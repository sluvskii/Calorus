import SwiftUI
import SwiftData
import UIKit

// MARK: - Dashboard Block Enum
enum DashboardBlock: String, CaseIterable, Identifiable {
    case summary, formula, quickActions, meals, activities, timeline
    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary: return "Сводка"
        case .formula: return "Формула дня"
        case .quickActions: return "Быстрые действия"
        case .meals: return "Приемы пищи"
        case .activities: return "Активность"
        case .timeline: return "Лента за сегодня"
        }
    }
}

// MARK: - View Modifier for Wiggle Animation
struct WiggleModifier: ViewModifier {
    let isEditing: Bool
    @State private var isWiggling = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isEditing ? (isWiggling ? 1.2 : -1.2) : 0))
            .onChange(of: isEditing) { newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                        isWiggling = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.1)) {
                        isWiggling = false
                    }
                }
            }
    }
}

// MARK: - View Modifier for Drag
struct DraggableModifier: ViewModifier {
    let isEditing: Bool
    let block: DashboardBlock

    func body(content: Content) -> some View {
        if isEditing {
            content
                .draggable(block.rawValue) {
                    content
                        .opacity(0.8)
                }
        } else {
            content
        }
    }
}

// MARK: - Main Dashboard View
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var consumptions: [Consumption]
    @Query private var activities: [Activity]
    @Query private var profiles: [UserProfile]

    @State private var showingAddConsumption = false
    @State private var showingAddActivity = false

    // Edit Mode States
    @AppStorage("dashboardBlocks") private var activeBlocksData: String = "summary,formula,quickActions,meals,activities,timeline"
    @State private var isEditing = false
    @State private var showingAddBlock = false

    private var activeBlocks: [DashboardBlock] {
        get {
            let blocks = activeBlocksData.split(separator: ",").compactMap { DashboardBlock(rawValue: String($0)) }
            return blocks.isEmpty ? DashboardBlock.allCases : blocks
        }
        nonmutating set {
            activeBlocksData = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }

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

    private var mealSummaries: [MealSummary] {
        MealType.allCases.map { type in
            let items = todayConsumptions.filter { $0.type == type }
            return MealSummary(
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
                    if isEditing {
                        Text("Перетащите виджеты, чтобы изменить их порядок")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 4)
                            .transition(.opacity)
                    }

                    ForEach(activeBlocks) { block in
                        blockView(for: block)
                            .overlay(alignment: .topLeading) {
                                if isEditing {
                                    Button {
                                        withAnimation(.spring) {
                                            var blocks = activeBlocks
                                            blocks.removeAll { $0 == block }
                                            activeBlocks = blocks
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .red)
                                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                    }
                                    .offset(x: -8, y: -8)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                if !isEditing {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    withAnimation(.spring) {
                                        isEditing = true
                                    }
                                }
                            }
                            .modifier(WiggleModifier(isEditing: isEditing))
                            .modifier(DraggableModifier(isEditing: isEditing, block: block))
                            .dropDestination(for: String.self) { (items: [String], location: CGPoint) in
                                guard let item = items.first, let sourceBlock = DashboardBlock(rawValue: item) else { return false }
                                withAnimation(.spring) {
                                    moveBlock(sourceBlock, to: block)
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }
                                return true
                            }
                            .scaleEffect(isEditing ? 0.96 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isEditing)
                    }

                    if isEditing {
                        Button {
                            showingAddBlock = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Добавить виджет")
                            }
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .padding(.top, 10)
                    }

                    if !isEditing {
                        Button {
                            withAnimation(.spring) {
                                isEditing = true
                            }
                        } label: {
                            Text("Настроить экран")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Готово") {
                            withAnimation(.spring) {
                                isEditing = false
                            }
                        }
                        .fontWeight(.bold)
                    }
                }
            }
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
            .sheet(isPresented: $showingAddBlock) {
                AddBlockSheet(activeBlocks: Binding(
                    get: { activeBlocks },
                    set: { activeBlocks = $0 }
                ))
            }
        }
    }

    @ViewBuilder
    private func blockView(for block: DashboardBlock) -> some View {
        switch block {
        case .summary: summaryCard
        case .formula: formulaCard
        case .quickActions: quickActionsCard
        case .meals: mealsCard
        case .activities: activitiesCard
        case .timeline: timelineCard
        }
    }

    private func moveBlock(_ source: DashboardBlock, to destination: DashboardBlock) {
        var blocks = activeBlocks
        guard let sourceIndex = blocks.firstIndex(of: source),
              let destIndex = blocks.firstIndex(of: destination),
              sourceIndex != destIndex else { return }

        blocks.remove(at: sourceIndex)
        let insertIndex = blocks.firstIndex(of: destination) ?? 0
        blocks.insert(source, at: sourceIndex < destIndex ? insertIndex + 1 : insertIndex)
        activeBlocks = blocks
    }

    // MARK: - Block Views
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Осталось \(caloriesRemaining) ккал")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(caloriesRemaining >= 0 ? .primary : .red)
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

// MARK: - Helper Views & Models

struct AddBlockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var activeBlocks: [DashboardBlock]

    var inactiveBlocks: [DashboardBlock] {
        DashboardBlock.allCases.filter { !activeBlocks.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                if inactiveBlocks.isEmpty {
                    Text("Все виджеты уже на экране")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(inactiveBlocks) { block in
                        Button {
                            withAnimation(.spring) {
                                activeBlocks.append(block)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Text(block.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Добавить виджет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct MealSummary {
    let type: MealType
    let total: Int
    let count: Int
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
