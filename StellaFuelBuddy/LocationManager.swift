import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let lm = CLLocationManager()
    private var lastLocation: CLLocation?

    @Published var isTracking = false
    @Published var milesThisRide: Double = 0.0   // 👈 miles

    override init() {
        super.init()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.distanceFilter = 10          // meters; tune for battery vs accuracy
        lm.allowsBackgroundLocationUpdates = true
        lm.pausesLocationUpdatesAutomatically = true
    }

    func requestAuthorization() {
        switch lm.authorizationStatus {
        case .notDetermined: lm.requestAlwaysAuthorization()
        case .authorizedWhenInUse: lm.requestAlwaysAuthorization()
        default: break
        }
    }

    func startRide() {
        guard !isTracking else { return }
        isTracking = true
        milesThisRide = 0
        lastLocation = nil
        lm.startUpdatingLocation()
    }

    func stopRide() {
        guard isTracking else { return }
        isTracking = false
        lm.stopUpdatingLocation()
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        for loc in locations where loc.horizontalAccuracy >= 0 {
            if let last = lastLocation {
                let meters = loc.distance(from: last)
                if meters > 1 {                            // basic noise gate
                    milesThisRide += meters * 0.000621371  // meters → miles
                }
            }
            lastLocation = loc
        }
    }
}
