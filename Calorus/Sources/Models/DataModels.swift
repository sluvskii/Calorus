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
}

enum ActivityType: String, Codable, CaseIterable {
    case walking = "Ходьба"
    case running = "Бег"
    case cycling = "Велосипед"
    case swimming = "Плавание"
    case strength = "Силовая тренировка"
    
    func caloriesPerMinute(weight: Double) -> Double {
        let met: Double
        switch self {
        case .walking: met = 3.5
        case .running: met = 9.8
        case .cycling: met = 7.5
        case .swimming: met = 8.0
        case .strength: met = 5.0
        }
        return (met * weight * 3.5) / 200.0
    }
}

@Model
final class Activity {
    var id: UUID
    var type: ActivityType
    var durationMinutes: Int
    var caloriesBurned: Int
    var date: Date
    
    init(type: ActivityType, durationMinutes: Int, caloriesBurned: Int, date: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
        self.date = date
    }
}

@Model
final class UserProfile {
    var id: UUID
    var weight: Double
    var height: Double
    var age: Int
    var isMale: Bool
    
    init(weight: Double = 70.0, height: Double = 170.0, age: Int = 30, isMale: Bool = true) {
        self.id = UUID()
        self.weight = weight
        self.height = height
        self.age = age
        self.isMale = isMale
    }
    
    @Transient
    var dailyCalorieGoal: Int {
        let weightFactor = 10.0 * weight
        let heightFactor = 6.25 * height
        let ageFactor = 5.0 * Double(age)
        
        let bmr: Double
        if isMale {
            bmr = weightFactor + heightFactor - ageFactor + 5.0
        } else {
            bmr = weightFactor + heightFactor - ageFactor - 161.0
        }
        
        return Int(bmr * 1.375) // Умножаем на базовый коэффициент активности
    }
}
