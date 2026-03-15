import SwiftUI

private struct SandGrain {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var radius: CGFloat
    var opacity: Double
}

struct HourglassView: View {
    let progress: Double

    @State private var grains: [SandGrain] = []
    @State private var lastUpdate: Date = .now
    @State private var initialized = false

    private let grainCount = 25
    private var isFlowing: Bool { progress > 0.001 && progress < 0.999 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                shadowEllipse(w: w, h: h)
                frameCap(w: w, h: h, top: true)
                frameCap(w: w, h: h, top: false)
                glassBody(w: w, h: h)
                topSand(w: w, h: h)
                bottomSand(w: w, h: h)
                dynamicSandLayer(w: w, h: h)
                glassHighlight(w: w, h: h)
            }
        }
        .aspectRatio(0.58, contentMode: .fit)
    }

    // MARK: - Shadow

    private func shadowEllipse(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(Color(hex: "#9B8FE9").opacity(0.08))
            .frame(width: w * 0.6, height: h * 0.04)
            .offset(y: h * 0.48)
            .blur(radius: 3)
    }

    // MARK: - Frame Caps

    private func frameCap(w: CGFloat, h: CGFloat, top: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "#D0C8F0"),
                        Color(hex: "#B8ADE0"),
                        Color(hex: "#D0C8F0")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: w * 0.58, height: h * 0.03)
            .shadow(color: Color(hex: "#9B8FE9").opacity(0.15), radius: 2, y: top ? 1 : -1)
            .offset(y: top ? -h * 0.435 : h * 0.435)
    }

    // MARK: - Glass Body

    private func glassBody(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            HourglassOutlineShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color(hex: "#E8E5F8").opacity(0.10),
                            Color.white.opacity(0.06)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: w * 0.4
                    )
                )

            HourglassOutlineShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#C4BBE8").opacity(0.5),
                            Color(hex: "#A89DD4").opacity(0.3),
                            Color(hex: "#C4BBE8").opacity(0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.2
                )
        }
        .frame(width: w * 0.9, height: h * 0.85)
    }

    // MARK: - Top Sand (decreases with progress)

    private func topSand(w: CGFloat, h: CGFloat) -> some View {
        SandFillShape(progress: progress, isTop: true)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#E8C87A"), Color(hex: "#D4A853")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(HourglassOutlineShape())
            .frame(width: w * 0.9, height: h * 0.85)
            .animation(.linear(duration: 0.8), value: progress)
    }

    // MARK: - Bottom Sand (increases with progress)

    private func bottomSand(w: CGFloat, h: CGFloat) -> some View {
        SandFillShape(progress: progress, isTop: false)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#D4A853"), Color(hex: "#C49540")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(HourglassOutlineShape())
            .frame(width: w * 0.9, height: h * 0.85)
            .animation(.linear(duration: 0.8), value: progress)
    }

    // MARK: - Dynamic Sand Layer (Stream + Particles)

    private func dynamicSandLayer(w: CGFloat, h: CGFloat) -> some View {
        let cw = w * 0.9
        let ch = h * 0.85

        return TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                guard isFlowing else { return }

                let midX = size.width / 2
                let neckYPos = size.height * 0.50

                // Thin sand stream through the neck
                var streamPath = Path()
                streamPath.move(to: CGPoint(x: midX, y: neckYPos - size.height * 0.05))
                streamPath.addLine(to: CGPoint(x: midX, y: neckYPos + size.height * 0.08))
                context.stroke(
                    streamPath,
                    with: .color(Color(hex: "#D4A853").opacity(0.75)),
                    lineWidth: 1.5
                )

                // Falling sand grains
                for grain in grains {
                    let rect = CGRect(
                        x: grain.x - grain.radius,
                        y: grain.y - grain.radius,
                        width: grain.radius * 2,
                        height: grain.radius * 2
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color(hex: "#D4A853").opacity(grain.opacity))
                    )
                }
            }
            .onChange(of: timeline.date) { _, newDate in
                guard isFlowing else { return }
                tick(date: newDate, cw: cw, ch: ch)
            }
        }
        .frame(width: cw, height: ch)
        .clipShape(HourglassOutlineShape())
        .allowsHitTesting(false)
    }

    // MARK: - Glass Highlight

    private func glassHighlight(w: CGFloat, h: CGFloat) -> some View {
        HourglassHighlightShape()
            .fill(Color.white.opacity(0.25))
            .frame(width: w * 0.9, height: h * 0.85)
            .blur(radius: 1.5)
            .allowsHitTesting(false)
    }

    // MARK: - Particle System

    private func tick(date: Date, cw: CGFloat, ch: CGFloat) {
        if !initialized {
            grains = (0..<grainCount).map { _ in
                spawnGrain(cw: cw, ch: ch, scattered: true)
            }
            initialized = true
            lastUpdate = date
            return
        }

        let dt = min(CGFloat(date.timeIntervalSince(lastUpdate)), 1.0 / 30.0)
        lastUpdate = date
        guard dt > 0 else { return }

        let neckYPos = ch * 0.50
        let gravity: CGFloat = ch * 1.5
        let bottomSurface = ch * CGFloat(0.95 - progress * 0.45)

        for i in grains.indices {
            grains[i].speed += gravity * dt
            grains[i].y += grains[i].speed * dt
            grains[i].x += CGFloat.random(in: -0.2...0.2)

            if grains[i].y >= bottomSurface - 1 || grains[i].y < neckYPos - 5 {
                grains[i] = spawnGrain(cw: cw, ch: ch, scattered: false)
            }
        }
    }

    private func spawnGrain(cw: CGFloat, ch: CGFloat, scattered: Bool) -> SandGrain {
        let midX = cw / 2
        let neckHalfW = cw * 0.04
        let neckYPos = ch * 0.50
        let bottomSurface = ch * CGFloat(0.95 - progress * 0.45)

        let y: CGFloat
        if scattered {
            let minY = neckYPos + 1
            let maxY = max(bottomSurface - 2, minY + 1)
            y = CGFloat.random(in: minY...maxY)
        } else {
            y = neckYPos + CGFloat.random(in: 0...(ch * 0.04))
        }

        return SandGrain(
            x: midX + CGFloat.random(in: -neckHalfW...neckHalfW),
            y: y,
            speed: CGFloat.random(in: 15...50),
            radius: CGFloat.random(in: 0.5...1.2),
            opacity: Double.random(in: 0.4...0.85)
        )
    }
}

// MARK: - Sand Fill Shape

private struct SandFillShape: Shape {
    var progress: Double
    let isTop: Bool

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let p = min(max(CGFloat(progress), 0), 1)
        let w = rect.width
        let h = rect.height
        let midX = rect.midX

        if isTop {
            let surfaceY = h * (0.05 + p * 0.45)
            let neckY = h * 0.50
            guard surfaceY < neckY - 1 else { return Path() }

            let dipFactor = 1 - abs(p * 2 - 1)
            let dip = h * 0.02 * dipFactor

            var path = Path()
            path.move(to: CGPoint(x: 0, y: surfaceY))
            path.addQuadCurve(
                to: CGPoint(x: w, y: surfaceY),
                control: CGPoint(x: midX, y: surfaceY + dip)
            )
            path.addLine(to: CGPoint(x: w, y: neckY))
            path.addLine(to: CGPoint(x: 0, y: neckY))
            path.closeSubpath()
            return path
        } else {
            let surfaceY = h * (0.95 - p * 0.45)
            let bottomY = h * 0.95
            let neckY = h * 0.50
            guard surfaceY < bottomY - 1 else { return Path() }

            let moundFactor = 1 - abs(p * 2 - 1)
            let mound = h * 0.02 * moundFactor

            var path = Path()
            if surfaceY <= neckY + 1 {
                path.addRect(CGRect(x: 0, y: neckY, width: w, height: bottomY - neckY))
            } else {
                path.move(to: CGPoint(x: 0, y: surfaceY))
                path.addQuadCurve(
                    to: CGPoint(x: w, y: surfaceY),
                    control: CGPoint(x: midX, y: surfaceY - mound)
                )
                path.addLine(to: CGPoint(x: w, y: bottomY))
                path.addLine(to: CGPoint(x: 0, y: bottomY))
                path.closeSubpath()
            }
            return path
        }
    }
}

// MARK: - Hourglass Outline Shape

private struct HourglassOutlineShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = rect.midX
        let midY = rect.midY
        let bulbHalf = w * 0.45
        let neckHalf = w * 0.04

        var path = Path()

        path.move(to: CGPoint(x: midX - bulbHalf, y: h * 0.05))
        path.addLine(to: CGPoint(x: midX + bulbHalf, y: h * 0.05))
        path.addCurve(
            to: CGPoint(x: midX + neckHalf, y: midY),
            control1: CGPoint(x: midX + bulbHalf, y: h * 0.32),
            control2: CGPoint(x: midX + neckHalf, y: h * 0.40)
        )
        path.addCurve(
            to: CGPoint(x: midX + bulbHalf, y: h * 0.95),
            control1: CGPoint(x: midX + neckHalf, y: h * 0.60),
            control2: CGPoint(x: midX + bulbHalf, y: h * 0.68)
        )
        path.addLine(to: CGPoint(x: midX - bulbHalf, y: h * 0.95))
        path.addCurve(
            to: CGPoint(x: midX - neckHalf, y: midY),
            control1: CGPoint(x: midX - bulbHalf, y: h * 0.68),
            control2: CGPoint(x: midX - neckHalf, y: h * 0.60)
        )
        path.addCurve(
            to: CGPoint(x: midX - bulbHalf, y: h * 0.05),
            control1: CGPoint(x: midX - neckHalf, y: h * 0.40),
            control2: CGPoint(x: midX - bulbHalf, y: h * 0.32)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - Glass Highlight Shape

private struct HourglassHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = rect.midX

        var path = Path()

        path.move(to: CGPoint(x: midX - w * 0.28, y: h * 0.10))
        path.addQuadCurve(
            to: CGPoint(x: midX - w * 0.06, y: h * 0.44),
            control: CGPoint(x: midX - w * 0.30, y: h * 0.30)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX - w * 0.25, y: h * 0.10),
            control: CGPoint(x: midX - w * 0.20, y: h * 0.30)
        )
        path.closeSubpath()

        path.move(to: CGPoint(x: midX - w * 0.25, y: h * 0.58))
        path.addQuadCurve(
            to: CGPoint(x: midX - w * 0.06, y: h * 0.56),
            control: CGPoint(x: midX - w * 0.06, y: h * 0.60)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX - w * 0.28, y: h * 0.88),
            control: CGPoint(x: midX - w * 0.20, y: h * 0.70)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX - w * 0.25, y: h * 0.58),
            control: CGPoint(x: midX - w * 0.30, y: h * 0.70)
        )
        path.closeSubpath()

        return path
    }
}
