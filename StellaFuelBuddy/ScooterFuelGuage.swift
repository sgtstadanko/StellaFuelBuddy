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
    var showTrack: Bool = false

    // Half‑circle sweep
    private let startDeg: Double = -90
    private let endDeg:   Double =  90

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let lineWidth = min(w, h) * 0.075          // stroke thickness scales with size
            let majorTickH = min(w, h) * 0.11
            let minorTickH = min(w, h) * 0.06
            let tickRadius  = min(w, h) * 0.52
            let labelRadius = min(w, h) * 0.68
            let hubSize     = min(w, h) * 0.085
            let needleLen   = min(w, h) * 0.55
            let frac = max(0, min(1, fraction))
            let needleAngle = Angle(degrees: startDeg + (endDeg - startDeg) * frac)

            ZStack {
                // Optional light track
                if showTrack {
                    arc(from: 0, to: 1)
                        .stroke(Color(.systemGray5),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .shadow(color: Color.black.opacity(0.06), radius: 3, y: 2)
                }

                // Optional colored zones
                if showZones {
                    arc(from: 0, to: dangerFrac)
                        .stroke(.red, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    arc(from: dangerFrac, to: warnFrac)
                        .stroke(.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    arc(from: warnFrac, to: 1)
                        .stroke(.green, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }

                // Ticks & labels
                ticks(tickRadius: tickRadius,
                      majorTickH: majorTickH,
                      minorTickH: minorTickH,
                      labelRadius: labelRadius)

                // E / F end labels
                endLabels(labelRadius: labelRadius)

                // Needle + hub
                needle(angle: needleAngle, length: needleLen)
                Circle()
                    .fill(Color.black)
                    .frame(width: hubSize, height: hubSize)
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: max(1, hubSize * 0.08)))
                    .shadow(radius: 1, y: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(Text("Fuel \(Int(frac * 100)) percent"))
        }
        // Provide a sensible default size when the parent doesn’t constrain it
        .aspectRatio(12/7, contentMode: .fit)
        .padding(.top, 6)
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

    private func ticks(tickRadius r: CGFloat,
                       majorTickH: CGFloat,
                       minorTickH: CGFloat,
                       labelRadius: CGFloat) -> some View {
        ZStack {
            // Major ticks at ¼, ½, ¾
            ForEach([0.25, 0.5, 0.75], id: \.self) { t in
                let angle = Angle(degrees: startDeg + (endDeg - startDeg) * t)
                Capsule()
                    .fill(Color.primary)
                    .frame(width: max(2, r * 0.035), height: majorTickH)
                    .offset(y: -r)
                    .rotationEffect(angle)
                Text(label(for: t))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .offset(labelOffset(for: angle, radius: labelRadius))
            }
            // Minor ticks every 1/8 (excluding ends)
            ForEach(1..<8) { j in
                let t = Double(j) * 0.125
                let angle = Angle(degrees: startDeg + (endDeg - startDeg) * t)
                Capsule()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: max(1.5, r * 0.025), height: minorTickH)
                    .offset(y: -r)
                    .rotationEffect(angle)
            }
        }
    }

    private func endLabels(labelRadius: CGFloat) -> some View {
        ZStack {
            Text("E")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .offset(labelOffset(for: .degrees(startDeg), radius: labelRadius * 0.92))
            Text("F")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .offset(labelOffset(for: .degrees(endDeg), radius: labelRadius * 0.92))
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

    private func needle(angle: Angle, length: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.15))
                .frame(width: max(2.5, length * 0.048), height: length)
                .offset(y: -length / 2)
                .rotationEffect(angle + .degrees(1.3))
                .blur(radius: 0.5)
            Rectangle()
                .fill(Color.red.opacity(0.9))
                .frame(width: max(2.5, length * 0.045), height: length)
                .offset(y: -length / 2)
                .rotationEffect(angle)
        }
    }
}
