import SwiftUI

struct ContentView: View {
    @StateObject private var lm   = LocationManager()
    @StateObject private var log  = RideLogStore()
    @StateObject private var fuel = FuelStore()

    @State private var rideStartTime: Date?
    @State private var showSettings = false

    // MARK: - Computed
    private var sinceFill: Double {
        log.milesSinceFill + (lm.isTracking ? lm.milesThisRide : 0)
    }
    private var totalRange: Double { fuel.totalRangeMiles }
    private var milesLeft: Double { max(0, totalRange - sinceFill) }

    private var statusColor: Color {
        if sinceFill < fuel.settings.warnAtMiles { return .green }
        if sinceFill < fuel.settings.dangerAtMiles { return .orange }
        return .red
    }
    private var fractionFull: Double {
        totalRange > 0 ? max(0, min(1, (totalRange - sinceFill) / totalRange)) : 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Miles-left + gauge
                    VStack(spacing: 6) {
                        Text("Miles left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f", milesLeft))
                            .font(.system(size: 112, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                    }

                    ScooterFuelGauge(
                        fraction: fractionFull,
                        warnFrac: fuel.settings.warnAtMiles / max(1, totalRange),
                        dangerFrac: fuel.settings.dangerAtMiles / max(1, totalRange),
                        showZones: false,
                        showTrack: false     // 👈 hides the gray half-circle
                    )

                    // Status details
                    GroupBox("Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            row("Miles this ride",  String(format: "%.1f", lm.milesThisRide))
                            row("Miles since fill", String(format: "%.1f", sinceFill))
                            row("Total range",      String(format: "%.0f mi", totalRange))
                            row("State",            stateText(for: sinceFill), boldRight: true)
                        }
                    }

                    // Controls
                    HStack(spacing: 12) {
                        Button(lm.isTracking ? "Stop Ride" : "Start Ride") {
                            if lm.isTracking {
                                stopAndLogRide()
                            } else {
                                lm.requestAuthorization()
                                rideStartTime = Date()
                                lm.startRide()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Fill Up") {
                            if lm.isTracking { stopAndLogRide() }
                            log.resetSinceFill()
                        }
                        .buttonStyle(.bordered)
                    }

                    // Recent rides
                    GroupBox("Recent Rides") {
                        if log.rides.isEmpty {
                            Text("No rides yet").foregroundStyle(.secondary)
                        } else {
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
                }
                .padding()
            }
            .navigationTitle("Stella Fuel Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(fuel: fuel)
            }
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

    private func stateText(for miles: Double) -> String {
        if miles < fuel.settings.warnAtMiles { return "OK" }
        if miles < fuel.settings.dangerAtMiles { return "Expect reserve soon" }
        return "On reserve — fuel up"
    }

    private func stopAndLogRide() {
        lm.stopRide()
        let end = Date()
        let start = rideStartTime ?? end
        let ride = Ride(start: start, end: end, miles: lm.milesThisRide)
        log.addRide(ride)
    }
}

#Preview { ContentView() }

