//
//  StellaFuelBuddyWidget.swift
//  StellaFuelBuddyWidget
//

import WidgetKit
import SwiftUI



// MARK: - Provider
struct FuelProvider: TimelineProvider {
    func placeholder(in context: Context) -> FuelEntry {
        FuelEntry(date: .now, milesLeftMiles: 88, fraction: 0.6, usesMetric: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (FuelEntry) -> Void) {
        let d = SharedStore.read()
        completion(FuelEntry(date: .now, milesLeftMiles: d.milesLeft, fraction: d.fractionFull, usesMetric: d.usesMetric))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelEntry>) -> Void) {
        let d = SharedStore.read()
        let entry = FuelEntry(date: .now, milesLeftMiles: d.milesLeft, fraction: d.fractionFull, usesMetric: d.usesMetric)
        // Refresh every 15 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - View
struct FuelGaugeWidgetView: View {
    var entry: FuelEntry

    private func formattedDistance() -> String {
        if entry.usesMetric {
            let km = entry.milesLeftMiles * 1.60934
            return "\(Int(km)) km"
        } else {
            return "\(Int(entry.milesLeftMiles)) mi"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Use the same needle gauge as the app
            ScooterFuelGauge(
                fraction: max(0, min(1, entry.fraction)),
                warnFrac: 0,
                dangerFrac: 0,
                showZones: false,
                showTrack: false
            )
            .frame(height: 72)

            Text(formattedDistance())
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget
@main
struct StellaFuelBuddyWidget: Widget {
    var body: some WidgetConfiguration {
        // NOTE: bumped kind to V2 to force iOS to drop any cached view
        StaticConfiguration(kind: "StellaFuelBuddyGaugeV2", provider: FuelProvider()) { entry in
            FuelGaugeWidgetView(entry: entry)
        }
        .configurationDisplayName("Fuel Gauge")
        .description("Scooter-style gauge with distance remaining.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}
