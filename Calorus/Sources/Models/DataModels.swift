import Foundation
import SwiftData

@Model
final class Consumption {
    var id: UUID
    var name: String
    var calories: Int
    var date: Date
    var type: MealType
    
    init(name: String, calories: Int, date: Date = Date(), type: MealType) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.date = date
        self.type = type
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Завтрак"
    case lunch = "Обед"
    case dinner = "Ужин"
    case snack = "Перекус"

    var symbolName: String {
        switch self {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.stars.fill"
        case .snack:
            return "leaf.fill"
        }
    }
}

enum BiologicalSex: String, Codable, CaseIterable {
    case male = "Мужской"
    case female = "Женский"

    var bmrOffset: Double {
        switch self {
        case .male:
            return 5
        case .female:
            return -161
        }
    }
}

enum LifestyleActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Сидячий"
    case light = "Легкая активность"
    case moderate = "Средняя активность"
    case high = "Высокая активность"

    var factor: Double {
        switch self {
        case .sedentary:
            return 1.2
        case .light:
            return 1.375
        case .moderate:
            return 1.55
        case .high:
            return 1.725
        }
    }

    var description: String {
        switch self {
        case .sedentary:
            return "Почти без движения в течение дня"
        case .light:
            return "Немного ходьбы и бытовой активности"
        case .moderate:
            return "Регулярная активность или тренировки"
        case .high:
            return "Много движения или тяжелые тренировки"
        }
    }
}

enum GoalPreference: String, Codable, CaseIterable {
    case lose = "Снижение веса"
    case maintain = "Поддержание"
    case gain = "Набор массы"

    var calorieOffset: Double {
        switch self {
        case .lose:
            return -400
        case .maintain:
            return 0
        case .gain:
            return 250
        }
    }
}

enum ActivityInputKind: String, Codable {
    case steps
    case minutes
}

enum ActivityType: String, Codable, CaseIterable {
    case walking = "Ходьба"
    case running = "Бег"
    case cycling = "Велосипед"
    case swimming = "Плавание"
    case strengthTraining = "Силовая тренировка"
    case yoga = "Йога"

    var symbolName: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "figure.outdoor.cycle"
        case .swimming:
            return "figure.pool.swim"
        case .strengthTraining:
            return "dumbbell.fill"
        case .yoga:
            return "figure.flexibility"
        }
    }

    var inputKind: ActivityInputKind {
        switch self {
        case .walking:
            return .steps
        case .running, .cycling, .swimming, .strengthTraining, .yoga:
            return .minutes
        }
    }

    var inputTitle: String {
        switch inputKind {
        case .steps:
            return "Шаги"
        case .minutes:
            return "Минуты"
        }
    }

    var inputPlaceholder: String {
        switch inputKind {
        case .steps:
            return "Например, 6500"
        case .minutes:
            return "Например, 40"
        }
    }

    private var metValue: Double {
        switch self {
        case .walking:
            return 3.5
        case .running:
            return 8.3
        case .cycling:
            return 7.5
        case .swimming:
            return 6.0
        case .strengthTraining:
            return 5.0
        case .yoga:
            return 2.8
        }
    }

    private func durationMinutes(for inputValue: Double) -> Double {
        switch inputKind {
        case .steps:
            return inputValue / 100
        case .minutes:
            return inputValue
        }
    }

    func estimateCalories(inputValue: Double, weightKg: Double) -> Int {
        let safeInput = max(inputValue, 0)
        let safeWeight = max(weightKg, 35)
        let duration = durationMinutes(for: safeInput)
        let calories = metValue * 3.5 * safeWeight / 200 * duration
        return max(Int(calories.rounded()), 0)
    }

    func detailText(for inputValue: Double) -> String {
        switch inputKind {
        case .steps:
            return "\(Int(inputValue)) шагов"
        case .minutes:
            return "\(Int(inputValue)) мин"
        }
    }
}

@Model
final class Activity {
    var id: UUID
    var name: String
    var type: ActivityType
    var inputValue: Double
    var caloriesBurned: Int
    var date: Date

    init(type: ActivityType, inputValue: Double, caloriesBurned: Int, date: Date = Date()) {
        self.id = UUID()
        self.name = type.rawValue
        self.type = type
        self.inputValue = inputValue
        self.caloriesBurned = caloriesBurned
        self.date = date
    }
}

@Model
final class UserProfile {
    var id: UUID
    var dailyCalorieGoal: Int
    var weightKg: Double
    var heightCm: Double
    var age: Int
    var sex: BiologicalSex
    var lifestyle: LifestyleActivityLevel
    var goalPreference: GoalPreference

    init(
        dailyCalorieGoal: Int = 2000,
        weightKg: Double = 70,
        heightCm: Double = 175,
        age: Int = 30,
        sex: BiologicalSex = .male,
        lifestyle: LifestyleActivityLevel = .light,
        goalPreference: GoalPreference = .maintain
    ) {
        self.id = UUID()
        self.dailyCalorieGoal = dailyCalorieGoal
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.sex = sex
        self.lifestyle = lifestyle
        self.goalPreference = goalPreference
        recalculateDailyCalorieGoal()
    }

    func recalculateDailyCalorieGoal() {
        let safeWeight = max(weightKg, 35)
        let safeHeight = max(heightCm, 130)
        let safeAge = max(age, 14)
        let bmr = (10 * safeWeight) + (6.25 * safeHeight) - (5 * Double(safeAge)) + sex.bmrOffset
        let target = (bmr * lifestyle.factor) + goalPreference.calorieOffset
        dailyCalorieGoal = max(Int(target.rounded()), 1200)
    }
}
