import Foundation
import Combine

struct RideEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let distanceMiles: Double

    init(id: UUID = UUID(), date: Date, distanceMiles: Double) {
        self.id = id
        self.date = date
        self.distanceMiles = distanceMiles
    }
}

final class RideLog: ObservableObject {
    static let shared = RideLog()

    @Published private(set) var rides: [RideEntry] = []
    @Published private(set) var milesSinceFill: Double = 0.0

    private let ridesKey = "rideLog.rides.v1"
    private let sinceFillKey = "rideLog.milesSinceFill.v1"

    private init() { load() }

    // MARK: Actions
    func addRide(_ ride: RideEntry) {
        rides.append(ride)
        milesSinceFill += ride.distanceMiles
        save()
    }

    func resetSinceFill() {
        milesSinceFill = 0
        save()
    }

    // MARK: Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(rides) {
            UserDefaults.standard.set(data, forKey: ridesKey)
        }
        UserDefaults.standard.set(milesSinceFill, forKey: sinceFillKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: ridesKey),
           let decoded = try? JSONDecoder().decode([RideEntry].self, from: data) {
            rides = decoded
        }
        milesSinceFill = UserDefaults.standard.double(forKey: sinceFillKey)
    }
}

