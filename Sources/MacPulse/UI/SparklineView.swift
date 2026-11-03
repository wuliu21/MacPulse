import SwiftUI

public struct SparklineView: View {
    public let values: [Double]
    public let accentColor: Color
    public let height: CGFloat

    public init(values: [Double], accentColor: Color, height: CGFloat = 34) {
        self.values = values
        self.accentColor = accentColor
        self.height = height
    }

    public var body: some View {
        Canvas { context, size in
            guard values.count >= 2, size.width > 4, size.height > 4 else { return }

            // Draw subtle grid lines at 25%, 50%, 75%
            let gridColor = Color.white.opacity(0.08)
            for fraction in [0.25, 0.5, 0.75] {
                let y = size.height * CGFloat(fraction)
                var gridPath = Path()
                gridPath.move(to: CGPoint(x: 0, y: y))
                gridPath.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(gridPath, with: .color(gridColor), lineWidth: 0.5)
            }

            let count = values.count
            let stepX = size.width / CGFloat(max(1, count - 1))
            let insetY: CGFloat = 2.0
            let usableHeight = max(1.0, size.height - insetY * 2)

            var points: [CGPoint] = []
            points.reserveCapacity(count)

            for (idx, val) in values.enumerated() {
                let clamped = min(100.0, max(0.0, val))
                let x = CGFloat(idx) * stepX
                let y = insetY + usableHeight * CGFloat(1.0 - clamped / 100.0)
                points.append(CGPoint(x: x, y: y))
            }

            // Build line path
            var linePath = Path()
            linePath.move(to: points[0])
            for i in 1..<points.count {
                linePath.addLine(to: points[i])
            }

            // Build fill path
            var fillPath = linePath
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()

            let gradient = Gradient(colors: [
                accentColor.opacity(0.42),
                accentColor.opacity(0.03)
            ])
            context.fill(
                fillPath,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            context.stroke(
                linePath,
                with: .color(accentColor),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )

            // Latest point glow indicator
            if let last = points.last {
                let glowRect = CGRect(x: last.x - 3.5, y: last.y - 3.5, width: 7, height: 7)
                context.fill(Path(ellipseIn: glowRect), with: .color(accentColor.opacity(0.35)))
                let dotRect = CGRect(x: last.x - 2.0, y: last.y - 2.0, width: 4, height: 4)
                context.fill(Path(ellipseIn: dotRect), with: .color(accentColor))
            }
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

public struct PerCoreMiniBarsView: View {
    public let usages: [Double]
    public let eCoreCount: Int

    public init(usages: [Double], eCoreCount: Int) {
        self.usages = usages
        self.eCoreCount = eCoreCount
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(Array(usages.enumerated()), id: \.offset) { idx, val in
                let isECore = idx < eCoreCount
                let barColor: Color = isECore
                    ? Color(red: 0.35, green: 0.78, blue: 1.0)
                    : Formatters.metricColor(percent: val)

                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.white.opacity(0.10))
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(barColor)
                            .frame(height: max(2, geo.size.height * CGFloat(min(100, max(0, val)) / 100.0)))
                    }
                }
                .frame(height: 16)
            }
        }
    }
}
