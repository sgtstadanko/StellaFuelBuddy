import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    @Published var isTracking: Bool = false
    @Published var distanceSinceStartMiles: Double = 0.0

    private let lm = CLLocationManager()
    private var lastLocation: CLLocation?

    private override init() {
        super.init()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.distanceFilter = 10 // meters; tradeoff of battery vs. accuracy
        lm.allowsBackgroundLocationUpdates = true
        lm.pausesLocationUpdatesAutomatically = true
    }

    // MARK: Permissions
    func requestAuthorization() {
        switch lm.authorizationStatus {
        case .notDetermined:
            lm.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            // upgrade so tracking works when the screen is off
            lm.requestAlwaysAuthorization()
        default: break
        }
    }

    // MARK: Ride control
    func startRide() {
        guard !isTracking else { return }
        distanceSinceStartMiles = 0
        lastLocation = nil
        isTracking = true
        lm.startUpdatingLocation()
    }

    func stopRide() {
        guard isTracking else { return }
        isTracking = false
        lm.stopUpdatingLocation()
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        for loc in locations where loc.horizontalAccuracy >= 0 {
            if let last = lastLocation {
                let meters = loc.distance(from: last)
                if meters > 1 { // simple noise gate
                    distanceSinceStartMiles += meters * 0.000621371
                }
            }
            lastLocation = loc
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // no-op, but you could react here if needed
    }
}

