import SwiftUI
import CoreLocation
import WidgetKit

struct Toast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.bold())
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal)
            .shadow(radius: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: message)
    }
}

struct ContentView: View {
    // Singletons
    @StateObject private var lm   = LocationManager.shared
    @StateObject private var log  = RideLog.shared
    @StateObject private var fuel = FuelStore()

    @State private var toastMessage: String?
    @State private var lastBand: FuelBand = .ok

    enum FuelBand: Int {
        case ok = 0, warn = 1, danger = 2
    }

    private var currentBand: FuelBand {
        if sinceFill < fuel.settings.warnAtMiles { return .ok }
        if sinceFill < fuel.settings.dangerAtMiles { return .warn }
        return .danger
    }

    // UI state
    @State private var rideStartTime: Date?
    @State private var showSettings = false

    // MARK: - Computed
    private var sinceFill: Double {
        log.milesSinceFill + (lm.isTracking ? lm.distanceSinceStartMiles : 0)
    }
    private var totalRange: Double { fuel.totalRangeMiles }           // miles (canonical)
    private var milesLeft: Double { max(0, totalRange - sinceFill) }  // miles (canonical)

    private var statusColor: Color {
        if sinceFill < fuel.settings.warnAtMiles { return .green }
        if sinceFill < fuel.settings.dangerAtMiles { return .orange }
        return .red
    }
    private var fractionFull: Double {
        guard totalRange > 0 else { return 0 }
        return max(0, min(1, (totalRange - sinceFill) / totalRange))
    }

    // MARK: - Widget sync
    /// Writes the latest values for the widget to read via App Group
    private func writeShared() {
        SharedStore.write(
            milesLeft: milesLeft,                         // canonical miles
            fractionFull: fractionFull,                   // 0...1
            usesMetric: DistanceFormatter.usesMetric(fuel.settings.unitPreference)
        )
    }

    var body: some View {
        let pref = fuel.settings.unitPreference

        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {

                        // Big miles-left readout
                        VStack(spacing: 6) {
                            Text("Miles left")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(Int(DistanceFormatter.value(miles: milesLeft, pref: pref))) \(DistanceFormatter.unit(pref: pref))")
                                .font(.system(size: 126, weight: .bold, design: .rounded))
                                .foregroundStyle(statusColor)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }

                        // Analog scooter gauge
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
                                row("Miles this ride",
                                    DistanceFormatter.format(miles: lm.distanceSinceStartMiles, pref: pref))
                                row("Since last fill",
                                    DistanceFormatter.format(miles: sinceFill, pref: pref))
                                row("Total range",
                                    String(format: "%.0f %@", DistanceFormatter.value(miles: totalRange, pref: pref),
                                           DistanceFormatter.unit(pref: pref)))
                                row("State", stateText(for: sinceFill), boldRight: true)
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
                                // Update shared + refresh widget immediately
                                writeShared()
                                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGauge")
                            }
                            .buttonStyle(.bordered)
                        }

                        // Recent rides (stable in ScrollView)
                        GroupBox("Recent Rides") {
                            let lastTen = Array(log.rides.suffix(10)).reversed()
                            if lastTen.isEmpty {
                                Text("No rides yet").foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(lastTen) { ride in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(DistanceFormatter.format(miles: ride.distanceMiles, pref: pref))
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

                VStack {
                    if let msg = toastMessage {
                        Toast(message: msg)
                            .zIndex(1)
                    }
                    Spacer()
                }
                .animation(.easeInOut, value: toastMessage)
                .transition(.move(edge: .top).combined(with: .opacity))
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
        // Keep widget data fresh
        .onAppear { 
            writeShared()
            lastBand = currentBand
        }
        .onChange(of: lm.distanceSinceStartMiles) { _ in writeShared() }
        .onChange(of: log.milesSinceFill) { _ in writeShared() }
        .onChange(of: fuel.settings.unitPreference) { _ in writeShared() }
        .onChange(of: currentBand) { newBand in
            if newBand.rawValue > lastBand.rawValue {
                switch newBand {
                case .warn:
                    toastMessage = "Warning: approaching reserve"
                case .danger:
                    toastMessage = "Danger: on reserve — fuel up"
                default:
                    break
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        toastMessage = nil
                    }
                }
            }
            lastBand = newBand
        }
        // NFC / App Intents listener
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
                writeShared()
                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGauge")
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

        // Always log a ride entry (even 0.0 helps verify wiring)
        let entry = RideEntry(date: start, distanceMiles: miles)
        log.addRide(entry)

        rideStartTime = nil

        // Update shared + refresh widget immediately
        writeShared()
        WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGauge")
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

#Preview { ContentView() }
