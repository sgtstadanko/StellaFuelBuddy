//
//  FuelEntry.swift
//

import WidgetKit
import SwiftUI

struct FuelEntry: TimelineEntry {
    let date: Date
    let milesLeftMiles: Double   // canonical miles
    let fraction: Double         // 0...1
    let usesMetric: Bool
}
