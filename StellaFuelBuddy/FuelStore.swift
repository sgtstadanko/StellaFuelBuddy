import Foundation

struct FuelSettings: Codable {
    var tankGal: Double = 1.45
    var mpg: Double = 56
    var warnAtMiles: Double = 50
    var dangerAtMiles: Double = 66
    var unitPreference: UnitPreference = .system   // NEW

    static let defaults = FuelSettings()
}

final class FuelStore: ObservableObject {
    @Published var settings: FuelSettings = {
        if let data = UserDefaults.standard.data(forKey: "fuelSettings"),
           let s = try? JSONDecoder().decode(FuelSettings.self, from: data) {
            return s
        }
        return .defaults
    }() {
        didSet { save() }
    }
    
    init() {
        // One-time migration from old defaults (1.8 gal / 70 mpg / 100/120 mi thresholds)
        if settings.tankGal == 1.8 && settings.mpg == 70 &&
           settings.warnAtMiles == 100 && settings.dangerAtMiles == 120 {
            settings = .defaults
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "fuelSettings")
        }
    }

    /// Total range in MILES (internal canonical unit)
    var totalRangeMiles: Double { settings.tankGal * settings.mpg }
}
