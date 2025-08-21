import SwiftUI

struct ContentView: View {
    // Singletons wired to your existing classes
    @StateObject private var lm   = LocationManager.shared
    @StateObject private var log  = RideLog.shared
    @StateObject private var fuel = FuelStore()

    // UI state
    @State private var rideStartTime: Date?
    @State private var showSettings = false

    // MARK: - Computed values
    private var sinceFill: Double {
        log.milesSinceFill + (lm.isTracking ? lm.distanceSinceStartMiles : 0)
    }
    private var totalRange: Double { fuel.totalRangeMiles }
    private var milesLeft: Double { max(0, totalRange - sinceFill) }

    private var statusColor: Color {
        if sinceFill < fuel.settings.warnAtMiles { return .green }
        if sinceFill < fuel.settings.dangerAtMiles { return .orange }
        return .red
    }
    private var fractionFull: Double {
        guard totalRange > 0 else { return 0 }
        return max(0, min(1, (totalRange - sinceFill) / totalRange))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Big miles-left readout
                    VStack(spacing: 6) {
                        Text("Miles left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f", milesLeft))
                            .font(.system(size: 126, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                    }

                    // Scooter-style half-circle gauge
                    ScooterFuelGauge(
                        fraction: fractionFull,
                        warnFrac: fuel.settings.warnAtMiles / max(1, totalRange),
                        dangerFrac: fuel.settings.dangerAtMiles / max(1, totalRange),
                        showZones: false,
                        showTrack: false
                    )

                    // Status
                    GroupBox("Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            row("Miles this ride",  String(format: "%.1f", lm.distanceSinceStartMiles))
                            row("Miles since fill", String(format: "%.1f", sinceFill))
                            row("Total range",      String(format: "%.0f mi", totalRange))
                            row("State",            stateText(for: sinceFill), boldRight: true)
                        }
                    }

                    // Controls
                    HStack(spacing: 12) {
                        Button(lm.isTracking ? "Stop Ride" : "Start Ride") {
                            if lm.isTracking { stopAndLogRide() } else { startRide() }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Fill Up") {
                            if lm.isTracking { stopAndLogRide() }
                            log.resetSinceFill()
                        }
                        .buttonStyle(.bordered)
                    }

                    // Recent rides (no List inside ScrollView)
                    GroupBox("Recent Rides") {
                        let lastTen = Array(log.rides.suffix(10)).reversed()
                        if lastTen.isEmpty {
                            Text("No rides yet").foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(lastTen) { ride in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(String(format: "%.1f mi", ride.distanceMiles))
                                                .font(.headline)
                                            Text(ride.date.formatted(.dateTime.month().day().hour().minute()))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline) // centers on iPhone
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Stella Fuel Buddy")
                        .font(.headline.bold())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(fuel: fuel)
            }
        }
        // App Intents listener (NFC Shortcut triggers)
        .onReceive(NotificationCenter.default.publisher(for: RideCommandCenter.shared.notificationName)) { note in
            guard let cmd = note.object as? RideCommandCenter.Command else { return }
            switch cmd {
            case .startRide:
                if !lm.isTracking { startRide() }
            case .stopRide:
                if lm.isTracking { stopAndLogRide() }
            case .fillUp:
                if lm.isTracking { stopAndLogRide() }
                log.resetSinceFill()
            }
        }
    }

    // MARK: - Actions

    private func startRide() {
        lm.requestAuthorization()
        rideStartTime = Date()
        lm.startRide()
    }

    private func stopAndLogRide() {
        lm.stopRide()
        let end = Date()
        let start = rideStartTime ?? end
        let miles = lm.distanceSinceStartMiles

        // Always log a ride (even 0.0 mi helps verify wiring)
        let entry = RideEntry(date: start, distanceMiles: miles)
        log.addRide(entry)

        rideStartTime = nil
    }

    // MARK: - UI helpers

    private func row(_ left: String, _ right: String, boldRight: Bool = false) -> some View {
        HStack {
            Text(left)
            Spacer()
            (boldRight ? Text(right).bold() : Text(right))
                .foregroundStyle(.secondary)
        }
    }

    private func stateText(for miles: Double) -> String {
        if miles < fuel.settings.warnAtMiles { return "OK" }
        if miles < fuel.settings.dangerAtMiles { return "Expect reserve soon" }
        return "On reserve — fuel up"
    }
}

#Preview {
    ContentView()
}

