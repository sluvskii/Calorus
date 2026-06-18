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

@Model
final class Activity {
    var id: UUID
    var name: String
    var caloriesBurned: Int
    var date: Date
    
    init(name: String, caloriesBurned: Int, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.caloriesBurned = caloriesBurned
        self.date = date
    }
}

@Model
final class UserProfile {
    var id: UUID
    var dailyCalorieGoal: Int
    
    init(dailyCalorieGoal: Int = 2000) {
        self.id = UUID()
        self.dailyCalorieGoal = dailyCalorieGoal
    }
}
