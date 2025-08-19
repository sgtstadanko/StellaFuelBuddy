import SwiftUI

struct ScooterFuelGauge: View {
    /// 0.0 = empty, 1.0 = full
    var fraction: Double
    /// thresholds as fractions of tank (0...1)
    var warnFrac: Double = 0.35
    var dangerFrac: Double = 0.15
    /// show green/amber/red zones
    var showZones: Bool = false
    /// show the light gray background track (half‑circle)
    var showTrack: Bool = false   // 👈 default off

    // Half‑circle sweep
    private let startDeg: Double = -90
    private let endDeg:   Double =  90

    var body: some View {
        let frac = max(0, min(1, fraction))
        let needleAngle = Angle(degrees: startDeg + (endDeg - startDeg) * frac)

        ZStack {
            // Optional light track
            if showTrack {
                arc(from: 0, to: 1)
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .shadow(color: Color.black.opacity(0.06), radius: 3, y: 2)
            }

            // Optional colored zones
            if showZones {
                arc(from: 0, to: dangerFrac)
                    .stroke(.red, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                arc(from: dangerFrac, to: warnFrac)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                arc(from: warnFrac, to: 1)
                    .stroke(.green, style: StrokeStyle(lineWidth: 18, lineCap: .round))
            }

            // Ticks & labels (only ¼, ½, ¾ here)
            ticks

            // E / F end labels
            endLabels

            // Needle + hub
            needle(angle: needleAngle)
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                .shadow(radius: 1, y: 1)
        }
        .frame(width: 240, height: 140)
        .padding(.top, 6)
        .accessibilityLabel(Text("Fuel \(Int(frac * 100)) percent"))
    }

    // MARK: - Pieces

    // 0...1 → trim 0.25..0.75 (exact 180°)
    private func trim(_ t: Double) -> CGFloat {
        CGFloat(0.25 + 0.5 * max(0, min(1, t)))
    }

    private func arc(from a: Double, to b: Double) -> some Shape {
        Circle()
            .trim(from: trim(a), to: trim(b))
            .rotation(.degrees(180)) // put 0 on the left
    }

    private var ticks: some View {
        ZStack {
            // Major ticks at ¼, ½, ¾
            ForEach([0.25, 0.5, 0.75], id: \.self) { t in
                let angle = Angle(degrees: startDeg + (endDeg - startDeg) * t)
                Capsule()
                    .fill(Color.primary)
                    .frame(width: 3, height: 16)
                    .offset(y: -52)
                    .rotationEffect(angle)
                Text(label(for: t))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .offset(labelOffset(for: angle, radius: 68))
            }
            // Minor ticks every 1/8 (excluding ends)
            ForEach(1..<8) { j in
                let t = Double(j) * 0.125
                let angle = Angle(degrees: startDeg + (endDeg - startDeg) * t)
                Capsule()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 2, height: 9)
                    .offset(y: -52)
                    .rotationEffect(angle)
            }
        }
    }

    private var endLabels: some View {
        ZStack {
            Text("E")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .offset(labelOffset(for: .degrees(startDeg), radius: 84))
            Text("F")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .offset(labelOffset(for: .degrees(endDeg), radius: 84))
        }
    }

    private func label(for t: Double) -> String {
        switch t {
        case 0.25: return "¼"
        case 0.50: return "½"
        case 0.75: return "¾"
        default:   return ""
        }
    }

    private func labelOffset(for angle: Angle, radius r: CGFloat) -> CGSize {
        let rad = CGFloat(angle.radians)
        return CGSize(width: sin(rad) * r, height: -cos(rad) * r)
    }

    private func needle(angle: Angle) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 3, height: 62)
                .offset(y: -31)
                .rotationEffect(angle + .degrees(1.3))
                .blur(radius: 0.5)
            Rectangle()
                .fill(Color.red.opacity(0.9))
                .frame(width: 3, height: 62)
                .offset(y: -31)
                .rotationEffect(angle)
        }
    }
}

