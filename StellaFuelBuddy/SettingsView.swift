import SwiftUI

struct SettingsView: View {
    @ObservedObject var fuel: FuelStore

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fuel Settings")) {
                    Stepper(value: $fuel.settings.tankGal, in: 0.5...5.0, step: 0.05) {
                        Text("Tank size: \(String(format: "%.2f", fuel.settings.tankGal)) gal")
                    }
                    Stepper(value: $fuel.settings.mpg, in: 10...200, step: 1) {
                        Text("MPG: \(Int(fuel.settings.mpg))")
                    }
                    Stepper(value: $fuel.settings.warnAtMiles, in: 10...500, step: 1) {
                        Text("Warn after: \(Int(fuel.settings.warnAtMiles)) mi")
                    }
                    Stepper(value: $fuel.settings.dangerAtMiles, in: 10...500, step: 1) {
                        Text("Reserve after: \(Int(fuel.settings.dangerAtMiles)) mi")
                    }
                }

                Section(header: Text("Units")) {
                    Picker("Unit Preference", selection: $fuel.settings.unitPreference) {
                        Text("Imperial").tag(UnitPreference.imperial)
                        Text("Metric").tag(UnitPreference.metric)
                        Text("System Default").tag(UnitPreference.system)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    NavigationLink("Open Calibration Helper") {
                        CalibrationHelperView(fuel: fuel)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(fuel: FuelStore())
}
