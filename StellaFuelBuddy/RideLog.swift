import Foundation

struct Ride: Codable, Identifiable {
    var id = UUID()
    var start: Date
    var end: Date
    var miles: Double
}

final class RideLogStore: ObservableObject {
    @Published private(set) var rides: [Ride] = []
    @Published var milesSinceFill: Double = 0         // running total since last fill

    private let ridesKey = "rideLog.rides"
    private let sinceFillKey = "rideLog.milesSinceFill"

    init() { load() }

    func addRide(_ ride: Ride) {
        rides.append(ride)
        milesSinceFill += ride.miles
        save()
    }

    func resetSinceFill() {
        milesSinceFill = 0
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rides) {
            UserDefaults.standard.set(data, forKey: ridesKey)
        }
        UserDefaults.standard.set(milesSinceFill, forKey: sinceFillKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: ridesKey),
           let decoded = try? JSONDecoder().decode([Ride].self, from: data) {
            rides = decoded
        }
        milesSinceFill = UserDefaults.standard.double(forKey: sinceFillKey)
    }
}
