import SwiftUI

struct ContentView: View {
    @StateObject private var lm = LocationManager()
    @StateObject private var log = RideLogStore()

    @State private var rideStartTime: Date?

    // quick settings (you can persist later if you want)
    @State private var tankGal: Double = 1.8
    @State private var mpg: Double = 70
    @State private var warnAt: Double = 100
    @State private var dangerAt: Double = 120

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                // STATUS
                GroupBox("Status") {
                    let sinceFill = log.milesSinceFill + (lm.isTracking ? lm.milesThisRide : 0)
                    VStack(alignment: .leading, spacing: 8) {
                        row("Miles this ride", String(format: "%.1f", lm.milesThisRide))
                        row("Miles since fill", String(format: "%.1f", sinceFill))
                        row("Est. miles left", String(format: "%.0f", max(0, tankGal * mpg - sinceFill)))
                        row("Status", status(for: sinceFill), boldRight: true)
                    }
                }

                // CONTROLS
                HStack(spacing: 12) {
                    Button(lm.isTracking ? "Stop Ride" : "Start Ride") {
                        if lm.isTracking {
                            // stop & log
                            lm.stopRide()
                            let end = Date()
                            let start = rideStartTime ?? end
                            let ride = Ride(start: start, end: end, miles: lm.milesThisRide)
                            log.addRide(ride)
                        } else {
                            lm.requestAuthorization()
                            rideStartTime = Date()
                            lm.startRide()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Fill Up") {
                        // if tracking, stop and log the partial ride first
                        if lm.isTracking {
                            lm.stopRide()
                            let end = Date()
                            let start = rideStartTime ?? end
                            let ride = Ride(start: start, end: end, miles: lm.milesThisRide)
                            log.addRide(ride)
                        }
                        log.resetSinceFill()
                    }
                    .buttonStyle(.bordered)
                }

                // SETTINGS (quick steppers)
                GroupBox("Settings") {
                    Stepper(value: $tankGal, in: 0.5...5, step: 0.1) {
                        row("Tank (gal)", String(format: "%.1f", tankGal))
                    }
                    Stepper(value: $mpg, in: 20...120, step: 1) {
                        row("MPG", String(format: "%.0f", mpg))
                    }
                    Stepper(value: $warnAt, in: 20...200, step: 5) {
                        row("Warn at", String(format: "%.0f mi", warnAt))
                    }
                    Stepper(value: $dangerAt, in: 30...250, step: 5) {
                        row("Danger at", String(format: "%.0f mi", dangerAt))
                    }
                }

                // RIDE LOG
                GroupBox("Recent Rides") {
                    if log.rides.isEmpty {
                        Text("No rides yet").foregroundStyle(.secondary)
                    } else {
                        // Show up to 10 most recent rides
                        List(log.rides.reversed().prefix(10)) { ride in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: "%.1f mi", ride.miles))
                                        .font(.headline)
                                    Text("\(ride.start.formatted(.dateTime.month().day().hour().minute())) → \(ride.end.formatted(.dateTime.hour().minute()))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .frame(maxHeight: 260)

                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Stella Fuel Buddy")
        }
    }

    // MARK: - Helpers

    private func row(_ left: String, _ right: String, boldRight: Bool = false) -> some View {
        HStack {
            Text(left)
            Spacer()
            (boldRight ? Text(right).bold() : Text(right))
                .foregroundStyle(.secondary)
        }
    }

    private func status(for miles: Double) -> String {
        if miles < warnAt { return "OK" }
        if miles < dangerAt { return "Expect reserve soon" }
        return "On reserve — fuel up"
    }
}

#Preview { ContentView() }

