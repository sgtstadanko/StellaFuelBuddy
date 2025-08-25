//
//  DistanceFormatter.swift
//  StellaFuelBuddy
//
//  Created by William Bradley on 8/21/25.
//
import Foundation

enum UnitPreference: String, Codable, CaseIterable, Identifiable {
    case system   // follow device locale
    case imperial // miles
    case metric   // kilometers

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:   return "System (Locale)"
        case .imperial: return "Miles (mi)"
        case .metric:   return "Kilometers (km)"
        }
    }
}

struct DistanceFormatter {
    /// Decide metric vs imperial based on preference + current locale
    static func usesMetric(_ pref: UnitPreference) -> Bool {
        switch pref {
        case .system:   return Locale.current.measurementSystem == .metric
        case .metric:   return true
        case .imperial: return false
        }
    }

    /// Convert stored miles → display string with correct unit
    static func format(miles: Double, pref: UnitPreference, decimals: Int = 1) -> String {
        let metric = usesMetric(pref)
        if metric {
            let km = miles * 1.60934
            return String(format: "%.\(decimals)f km", km)
        } else {
            return String(format: "%.\(decimals)f mi", miles)
        }
    }

    /// Convert stored miles → numeric in chosen unit
    static func value(miles: Double, pref: UnitPreference) -> Double {
        usesMetric(pref) ? miles * 1.60934 : miles
    }

    /// Unit label only
    static func unit(pref: UnitPreference) -> String {
        usesMetric(pref) ? "km" : "mi"
    }
}

