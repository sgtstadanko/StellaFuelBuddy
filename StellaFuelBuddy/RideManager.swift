import Foundation
import CoreLocation
import Combine

final class RideManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = false
    @Published var milesThisRide: Double = 0
    @Published var totalMilesSinceFill: Double = UserDefaults.standard.double(forKey: "milesSinceFill")

    private let lm = CLLocationManager()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        lm.delegate = self
        lm.allowsBackgroundLocationUpdates = true
        lm.pausesLocationUpdatesAutomatically = true
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.distanceFilter = 10 // meters
    }

    func requestPermissions() {
        switch lm.authorizationStatus {
        case .notDetermined: lm.requestAlwaysAuthorization()
        case .authorizedWhenInUse: lm.requestAlwaysAuthorization()
        default: break
        }
    }

    func startRide() {
        guard !isTracking else { return }
        milesThisRide = 0
        lastLocation = nil
        isTracking = true
        lm.startUpdatingLocation()
    }

    func stopRide() {
        guard isTracking else { return }
        isTracking = false
        lm.stopUpdatingLocation()
        totalMilesSinceFill += milesThisRide
        UserDefaults.standard.set(totalMilesSinceFill, forKey: "milesSinceFill")
    }

    func resetSinceFill() {
        totalMilesSinceFill = 0
        UserDefaults.standard.set(0.0, forKey: "milesSinceFill")
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        for loc in locations where loc.horizontalAccuracy >= 0 {
            if let last = lastLocation {
                let meters = loc.distance(from: last)
                if meters > 1 { milesThisRide += meters * 0.000621371 } // meters→miles
            }
            lastLocation = loc
        }
    }
}
