import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var fuel: FuelStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Fuel & Range") {
                    Stepper(value: $fuel.settings.tankGal, in: 0.5...5, step: 0.1) {
                        HStack { Text("Tank (gal)"); Spacer(); Text(String(format: "%.1f", fuel.settings.tankGal)).foregroundStyle(.secondary) }
                    }
                    Stepper(value: $fuel.settings.mpg, in: 20...120, step: 1) {
                        HStack { Text("MPG"); Spacer(); Text(String(format: "%.0f", fuel.settings.mpg)).foregroundStyle(.secondary) }
                    }
                }
                Section("Alerts") {
                    Stepper(value: $fuel.settings.warnAtMiles, in: 20...200, step: 5) {
                        HStack { Text("Warn at"); Spacer(); Text(String(format: "%.0f mi", fuel.settings.warnAtMiles)).foregroundStyle(.secondary) }
                    }
                    Stepper(value: $fuel.settings.dangerAtMiles, in: 30...250, step: 5) {
                        HStack { Text("Danger at"); Spacer(); Text(String(format: "%.0f mi", fuel.settings.dangerAtMiles)).foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

