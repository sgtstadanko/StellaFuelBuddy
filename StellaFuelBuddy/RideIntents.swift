import SwiftUI
import AppIntents

// MARK: - Command bus the UI listens to
@available(iOS 17.0, *)
final class RideCommandCenter {
    static let shared = RideCommandCenter()
    enum Command { case startRide, stopRide, fillUp }
    let notificationName = Notification.Name("RideCommandCenter.Command")
    func send(_ cmd: Command) {
        NotificationCenter.default.post(name: notificationName, object: cmd)
    }
}

// MARK: - Intents

@available(iOS 17.0, *)
struct StartRideIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Ride"
    static var description = IntentDescription("Begin a new ride and start mileage tracking.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { RideCommandCenter.shared.send(.startRide) }
        return .result()
    }
}

@available(iOS 17.0, *)
struct StopRideIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Ride"
    static var description = IntentDescription("Stop the current ride and save mileage.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { RideCommandCenter.shared.send(.stopRide) }
        return .result()
    }
}

@available(iOS 17.0, *)
struct FillUpIntent: AppIntent {
    static var title: LocalizedStringResource = "Fill Up"
    static var description = IntentDescription("Log a fuel stop and reset miles since fill.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { RideCommandCenter.shared.send(.fillUp) }
        return .result()
    }
}

// MARK: - App Shortcuts grouping (tile in Shortcuts)

@available(iOS 17.0, *)
struct RideShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: StartRideIntent(),
                phrases: [
                    "Start ride in \(.applicationName)",
                    "Begin ride with \(.applicationName)"
                ],
                shortTitle: "Start Ride",
                systemImageName: "scooter"          // SF Symbol
            ),
            AppShortcut(
                intent: StopRideIntent(),
                phrases: [
                    "Stop ride in \(.applicationName)"
                ],
                shortTitle: "Stop Ride",
                systemImageName: "stop.circle.fill" // SF Symbol
            ),
            AppShortcut(
                intent: FillUpIntent(),
                phrases: [
                    "Fill up in \(.applicationName)",
                    "Reset fuel in \(.applicationName)"
                ],
                shortTitle: "Fill Up",
                systemImageName: "fuelpump.fill"    // SF Symbol
            )
        ]
    }
}

