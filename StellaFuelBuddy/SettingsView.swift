import SwiftUI
import WidgetKit

struct SettingsView: View {
    @ObservedObject var fuel: FuelStore
    @State private var showCalibrator = false

    private let L_PER_GAL = 3.78541
    private let KM_PER_MI = 1.60934

    var body: some View {
        let pref = fuel.settings.unitPreference
        let metric = DistanceFormatter.usesMetric(pref)

        NavigationStack {
            Form {
                // Units first so the rest of the form reflects it
                Section("Units") {
                    Picker("Units", selection: $fuel.settings.unitPreference) {
                        ForEach(UnitPreference.allCases) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                }

                Section("Fuel & Range") {

                    // Tank size (stored in gallons; displayed/edited in gal or L)
                    Stepper(value: tankSizeBinding(metric: metric),
                            in: metric ? 2.0...20.0 : 0.5...5.0,
                            step: metric ? 0.1 : 0.05) {
                        let shown = tankSizeBinding(metric: metric).wrappedValue
                        Text(metric
                             ? String(format: "Tank size: %.1f L", shown)
                             : String(format: "Tank size: %.2f gal", shown))
                    }

                    // MPG stays in miles/gal (simple for now)
                    Stepper(value: $fuel.settings.mpg, in: 20...150, step: 1) {
                        if metric {
                            // show a helpful metric hint
                            let kmPerL = (fuel.settings.mpg * KM_PER_MI) / L_PER_GAL
                            Text("Economy: \(Int(fuel.settings.mpg)) MPG  (≈ \(String(format: "%.1f", kmPerL)) km/L)")
                        } else {
                            Text("Economy: \(Int(fuel.settings.mpg)) MPG")
                        }
                    }

                    // Warn threshold (stored in miles; displayed/edited in mi or km)
                    Stepper(value: warnBinding(metric: metric),
                            in: metric ? 10...800 : 10...600,
                            step: 1) {
                        let shown = warnBinding(metric: metric).wrappedValue
                        Text("Warn after \(Int(shown)) \(metric ? "km" : "mi")")
                    }

                    // Reserve threshold (stored in miles; displayed/edited in mi or km)
                    Stepper(value: reserveBinding(metric: metric),
                            in: metric ? 20...1000 : 20...600,
                            step: 1) {
                        let shown = reserveBinding(metric: metric).wrappedValue
                        Text("Reserve after \(Int(shown)) \(metric ? "km" : "mi")")
                    }
                }

                Section("Calibration") {
                    Button("Calibrate MPG") {
                        showCalibrator = true
                    }
                }

                Section {
                    Button(role: .destructive) {
                        fuel.settings = .defaults
                    } label: {
                        Text("Reset to Defaults")
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: fuel.settings.unitPreference) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGaugeV2")
            }
            .onChange(of: fuel.settings.tankGal) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGaugeV2")
            }
            .onChange(of: fuel.settings.mpg) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGaugeV2")
            }
            .onChange(of: fuel.settings.warnAtMiles) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGaugeV2")
            }
            .onChange(of: fuel.settings.dangerAtMiles) { _ in
                WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGaugeV2")
            }
            .sheet(isPresented: $showCalibrator) {
                MPGCalibratorView(fuel: fuel)
            }
        }
    }

    // MARK: - Bindings that convert to/from canonical units

    /// Tank size binding (canonical = gallons)
    private func tankSizeBinding(metric: Bool) -> Binding<Double> {
        Binding<Double>(
            get: {
                metric ? fuel.settings.tankGal * L_PER_GAL : fuel.settings.tankGal
            },
            set: { newShown in
                fuel.settings.tankGal = metric ? (newShown / L_PER_GAL) : newShown
            }
        )
    }

    /// Warn threshold binding (canonical = miles)
    private func warnBinding(metric: Bool) -> Binding<Double> {
        Binding<Double>(
            get: {
                metric ? fuel.settings.warnAtMiles * KM_PER_MI : fuel.settings.warnAtMiles
            },
            set: { newShown in
                fuel.settings.warnAtMiles = metric ? (newShown / KM_PER_MI) : newShown
            }
        )
    }

    /// Reserve threshold binding (canonical = miles)
    private func reserveBinding(metric: Bool) -> Binding<Double> {
        Binding<Double>(
            get: {
                metric ? fuel.settings.dangerAtMiles * KM_PER_MI : fuel.settings.dangerAtMiles
            },
            set: { newShown in
                fuel.settings.dangerAtMiles = metric ? (newShown / KM_PER_MI) : newShown
            }
        )
    }
}
