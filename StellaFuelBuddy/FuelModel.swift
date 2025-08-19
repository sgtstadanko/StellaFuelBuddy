import Foundation

struct FuelSettings: Codable {
    var tankGal: Double = 1.8
    var mpg: Double = 70
    var warnAtMiles: Double = 100
    var dangerAtMiles: Double = 120
    static let defaults = FuelSettings()
}

final class FuelStore: ObservableObject {
    @Published var settings: FuelSettings = {
        if let data = UserDefaults.standard.data(forKey: "fuelSettings"),
           let s = try? JSONDecoder().decode(FuelSettings.self, from: data) {
            return s
        }
        return .defaults
    }() { didSet { save() } }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "fuelSettings")
        }
    }

    func totalRangeMiles() -> Double { settings.tankGal * settings.mpg }

    func status(for milesSinceFill: Double) -> String {
        if milesSinceFill < settings.warnAtMiles { return "OK" }
        if milesSinceFill < settings.dangerAtMiles { return "Expect reserve soon" }
        return "On reserve — fuel up"
    }
}
