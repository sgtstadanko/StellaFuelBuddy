import SwiftUI
import WidgetKit

private struct NumberField: View {
    let title: String
    @Binding var value: String
    var body: some View {
        TextField(title, text: $value)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
    }
}

struct MPGCalibratorView: View {
    @ObservedObject var fuel: FuelStore
    @StateObject private var log = RideLog.shared
    @StateObject private var lm  = LocationManager.shared

    @Environment(\.dismiss) private var dismiss

    // Inputs
    @State private var gallonsAddedText: String = ""
    @State private var reserveMilesText: String = ""
    @State private var reserveGalText: String = String(format: "%.2f", 0.26) // Stella 4T default
    @State private var manualMilesText: String = ""

    // Output preview
    @State private var computedMPG: Double?
    @State private var method: Int = 0 // 0 = Pump, 1 = Reserve

    private var milesSinceFillNow: Double {
        // Canonical miles since last Fill button, including live ride if tracking
        log.milesSinceFill + (lm.isTracking ? lm.distanceSinceStartMiles : 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Method", selection: $method) {
                    Text("Pump Method").tag(0)
                    Text("Reserve Method").tag(1)
                }
                .pickerStyle(.segmented)

                if method == 0 { pumpMethod } else { reserveMethod }

                if let mpg = computedMPG {
                    Section("Result") {
                        Text("Estimated MPG: **\(String(format: "%.1f", mpg))**")
                        Button("Apply as New MPG") {
                            fuel.settings.mpg = mpg
                            WidgetCenter.shared.reloadTimelines(ofKind: "StellaFuelBuddyGaugeV2")
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("MPG Calibrator")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                // Prefill reserve miles with current since-fill if they just hit reserve
                reserveMilesText = String(format: "%.1f", milesSinceFillNow)
            }
        }
    }

    // MARK: - Pump method: MPG = miles_since_fill / gallons_added
    private var pumpMethod: some View {
        Section("Pump Method (most accurate)") {
            NumberField(title: "Miles since fill (leave blank for auto)", value: $manualMilesText)
            NumberField(title: "Gallons added (e.g., 1.19)", value: $gallonsAddedText)

            Button("Compute MPG") {
                let miles: Double
                if let override = Double(manualMilesText), override > 0 {
                    miles = override
                } else {
                    miles = milesSinceFillNow
                }
                guard let g = Double(gallonsAddedText), g > 0 else {
                    computedMPG = nil
                    return
                }
                computedMPG = miles / g
            }
        }
    }

    // MARK: - Reserve method: MPG = M / (T - R)
    private var reserveMethod: some View {
        Section("Reserve Method (quick)") {
            NumberField(title: "Miles at reserve (e.g., 66.5)", value: $reserveMilesText)

            HStack {
                Text("Tank size")
                Spacer()
                Text(String(format: "%.2f gal", fuel.settings.tankGal))
                    .foregroundStyle(.secondary)
            }
            NumberField(title: "Reserve size in gal (e.g., 0.26)", value: $reserveGalText)

            Button("Compute MPG") {
                guard
                    let M = Double(reserveMilesText), M > 0,
                    let R = Double(reserveGalText), R >= 0
                else {
                    computedMPG = nil
                    return
                }
                let T = fuel.settings.tankGal
                let usable = max(0.0, T - R)
                guard usable > 0 else { computedMPG = nil; return }
                computedMPG = M / usable
            }
        }
    }
}
