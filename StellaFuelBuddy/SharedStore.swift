//
//  SharedStore.swift
//  StellaFuelBuddy
//
//  Created by William Bradley on 8/21/25.
//
import Foundation

enum SharedStore {
    // Make sure this matches the App Group you added in Signing & Capabilities
    static let suite = UserDefaults(suiteName: "group.com.sgtstadanko.StellaFuelBuddy")!

    /// App writes these when values change (miles canonical)
    static func write(milesLeft: Double, fractionFull: Double, usesMetric: Bool) {
        suite.set(milesLeft, forKey: "milesLeft")       // canonical miles
        suite.set(fractionFull, forKey: "fractionFull") // 0...1
        suite.set(usesMetric, forKey: "usesMetric")     // for label (mi/km)
        suite.set(Date().timeIntervalSince1970, forKey: "updatedAt")
        suite.synchronize()
    }

    /// Widget reads latest snapshot
    static func read() -> (milesLeft: Double, fractionFull: Double, usesMetric: Bool, updatedAt: Date) {
        let m = suite.double(forKey: "milesLeft")
        let f = suite.double(forKey: "fractionFull")
        let u = suite.bool(forKey: "usesMetric")
        let t = suite.double(forKey: "updatedAt")
        return (m, f, u, Date(timeIntervalSince1970: t))
    }
}
