//
//  CalibrationHelperView.swift
//  StellaFuelBuddy
//
//  Created by William Bradley on 8/25/25.
//
import SwiftUI

struct CalibrationHelperView: View {
    @ObservedObject var fuel: FuelStore
    
    @State private var gallonsAdded: String = ""
    @State private var milesDriven: String = ""
    @State private var result: String?

    var body: some View {
        Form {
            Section(header: Text("Fill-up data")) {
                TextField("Gallons added", text: $gallonsAdded)
                    .keyboardType(.decimalPad)
                TextField("Miles driven", text: $milesDriven)
                    .keyboardType(.decimalPad)
            }

            Button("Calculate") {
                if let g = Double(gallonsAdded),
                   let m = Double(milesDriven),
                   g > 0 {
                    let mpg = m / g
                    let suggestedTank = g
                    result = String(
                        format: "MPG: %.1f\nSuggested tank size: %.2f gal",
                        mpg, suggestedTank
                    )
                }
            }

            if let r = result {
                Section(header: Text("Result")) {
                    Text(r)
                    Button("Apply to Settings") {
                        if let g = Double(gallonsAdded),
                           let m = Double(milesDriven),
                           g > 0 {
                            fuel.settings.mpg = m / g
                            fuel.settings.tankGal = g
                        }
                    }
                }
            }
        }
        .navigationTitle("Calibration Helper")
    }
}
