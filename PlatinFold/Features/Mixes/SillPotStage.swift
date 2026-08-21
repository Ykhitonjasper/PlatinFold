import SwiftUI

enum BenchPotKind: String {
    case basil
    case lemon
    case bottle
}

enum SillFocus: String, CaseIterable, Identifiable {
    case basil
    case bottle
    case lemon

    var id: String { rawValue }

    var chip: String {
        switch self {
        case .basil: return "Basil · 18 cm"
        case .bottle: return "FloraGro 2 ml"
        case .lemon: return "Lemon · east"
        }
    }

    var hint: String {
        switch self {
        case .basil: return "Sways the basil and drops a pour"
        case .bottle: return "Tips the bottle into the basil"
        case .lemon: return "Turns the lemon"
        }
    }

    var potKind: BenchPotKind {
        switch self {
        case .basil: return .basil
        case .bottle: return .bottle
        case .lemon: return .lemon
        }
    }
}

struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.spring(response: 0.26, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

struct SillPotStage: View {
    let kind: BenchPotKind
    let caption: String
    var canvasHeight: CGFloat = 148
    @State private var spinTick = 0
    @State private var dragTilt: CGFloat = 0

    var body: some View {
        VStack(spacing: AppMetrics.tightSpacing) {
            SoloSillArt(kind: kind, pulse: spinTick, dragTilt: dragTilt)
                .frame(maxWidth: .infinity)
                .frame(height: canvasHeight)
                .accessibilityHidden(true)
                .gesture(soloDrag)

            TagChip(title: caption, systemImage: kind == .bottle ? "drop" : "leaf")
        }
        .contentShape(Rectangle())
        .onTapGesture { spinTick += 1 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption)
        .accessibilityHint(kind == .bottle ? "Drag up to tip, or tap to pour" : "Sways the plant")
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: spinTick)
    }

    private var soloDrag: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard kind == .bottle else { return }
                dragTilt = min(0.75, max(0, -value.translation.height / 110))
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    if dragTilt > 0.35 { spinTick += 1 }
                    dragTilt = 0
                }
            }
    }
}

struct SillBenchStage: View {
    @State private var focus: SillFocus = .bottle
    @State private var basilPulse = 0
    @State private var bottlePulse = 0
    @State private var lemonPulse = 0
    @State private var dropToken = 0
    @State private var bottleTilt: CGFloat = 0
    @State private var dragHint = false

    var body: some View {
        VStack(spacing: AppMetrics.contentSpacing) {
            SillBenchArt(
                focus: focus,
                basilPulse: basilPulse,
                bottlePulse: bottlePulse,
                lemonPulse: lemonPulse,
                dropToken: dropToken,
                bottleTilt: bottleTilt
            )
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .contentShape(Rectangle())
            .gesture(sillDrag)
            .overlay(alignment: .topTrailing) {
                if dragHint {
                    Text("Drag up to pour · swipe to pick")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.textMono)
                        .padding(.horizontal, AppMetrics.tightSpacing)
                        .padding(.vertical, 4)
                        .background(AppTheme.bgElevated, in: Capsule())
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).delay(0.4)) { dragHint = true }
                withAnimation(.easeInOut(duration: 0.4).delay(2.4)) { dragHint = false }
            }

            ChipRow {
                ForEach(SillFocus.allCases) { item in
                    FilterChip(title: item.chip, isSelected: focus == item) {
                        play(item)
                    }
                }
            }
        }
        .sensoryFeedback(
            .impact(flexibility: .soft, intensity: 0.85),
            trigger: basilPulse + bottlePulse + lemonPulse
        )
        .sensoryFeedback(.selection, trigger: focus)
    }

    private var sillDrag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let horizontal = abs(value.translation.width) > abs(value.translation.height)
                if horizontal {
                    bottleTilt = 0
                    return
                }
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.86)) {
                    focus = .bottle
                    bottleTilt = min(0.78, max(0, -value.translation.height / 100))
                }
            }
            .onEnded { value in
                let horizontal = abs(value.translation.width) > abs(value.translation.height) * 1.1
                if horizontal, abs(value.translation.width) > 40 {
                    let order = SillFocus.allCases
                    if let index = order.firstIndex(of: focus) {
                        if value.translation.width < 0, index < order.count - 1 {
                            play(order[index + 1])
                        } else if value.translation.width > 0, index > 0 {
                            play(order[index - 1])
                        }
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                        bottleTilt = 0
                    }
                    return
                }

                let shouldPour = bottleTilt > 0.32
                withAnimation(.spring(response: 0.48, dampingFraction: 0.7)) {
                    bottleTilt = 0
                }
                if shouldPour {
                    play(.bottle)
                }
            }
    }

    private func play(_ item: SillFocus) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            focus = item
        }
        switch item {
        case .basil:
            basilPulse += 1
            dropToken += 1
        case .bottle:
            bottlePulse += 1
            dropToken += 1
        case .lemon:
            lemonPulse += 1
        }
    }
}

struct SillStageHero: View {
    let lastLine: MixLineItem?
    let appeared: Bool
    let onLastTank: () -> Void

    var body: some View {
        SectionCard(title: "On the sill") {
            SillBenchStage()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.62, dampingFraction: 0.86), value: appeared)

            if let lastLine {
                DetailRow(label: "Last mix", value: lastLine.resultText, isProminent: true)
            }

            CTAButton(
                title: "Last tank",
                systemImage: "clock",
                emphasis: .secondary,
                hint: "Opens the most recent mix on this bench"
            ) {
                onLastTank()
            }
        }
    }
}

struct TodayMixHero: View {
    let bench: BenchItem
    let lastLine: MixLineItem?
    let appeared: Bool
    let onMixTank: () -> Void
    let onLastTank: () -> Void

    var body: some View {
        SectionCard(title: "Guard this sill") {
            SillBenchStage()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.62, dampingFraction: 0.86), value: appeared)

            HStack(alignment: .bottom, spacing: AppMetrics.contentSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bench.name)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(bench.location)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer(minLength: 0)
                if let lastLine {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(lastLine.resultText)
                            .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(AppTheme.textMono)
                        Text("Last exact dose")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                    }
                }
            }

            CTAButton(title: "Mix a tank", systemImage: "drop.fill") {
                onMixTank()
            }

            if lastLine != nil {
                CTAButton(
                    title: "Last tank",
                    systemImage: "clock",
                    emphasis: .secondary
                ) {
                    onLastTank()
                }
            }
        }
    }
}

// MARK: - Editorial sill (SwiftUI, 2026)

private struct SillBenchArt: View {
    let focus: SillFocus
    let basilPulse: Int
    let bottlePulse: Int
    let lemonPulse: Int
    let dropToken: Int
    var bottleTilt: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let board = sillBoardRect(in: size)
                drawBoard(canvas, board: board)

                let basilX = board.minX + board.width * 0.22
                let bottleX = board.midX
                let lemonX = board.minX + board.width * 0.78
                let potBase = board.minY + 4

                drawPotPlant(
                    canvas,
                    kind: .basil,
                    centerX: basilX,
                    baseY: potBase,
                    scale: focus == .basil ? 1.06 : 0.98,
                    sway: sin(t * 1.4) * 0.045 + (basilPulse % 2 == 0 ? 0 : 0.08),
                    highlight: focus == .basil
                )
                drawBottle(
                    canvas,
                    centerX: bottleX,
                    baseY: potBase,
                    tip: bottlePulse,
                    time: t,
                    tilt: Double(bottleTilt),
                    highlight: focus == .bottle
                )
                drawPotPlant(
                    canvas,
                    kind: .lemon,
                    centerX: lemonX,
                    baseY: potBase,
                    scale: focus == .lemon ? 1.06 : 0.98,
                    sway: sin(t * 1.15 + 1.2) * 0.035 + (lemonPulse % 2 == 0 ? 0 : 0.06),
                    highlight: focus == .lemon
                )

                if dropToken > 0 {
                    drawFallingDrop(canvas, board: board, token: dropToken, time: t)
                }
            }
        }
        .drawingGroup()
    }
}

private struct SoloSillArt: View {
    let kind: BenchPotKind
    let pulse: Int
    var dragTilt: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let board = CGRect(
                    x: size.width * 0.12,
                    y: size.height * 0.72,
                    width: size.width * 0.76,
                    height: size.height * 0.12
                )
                drawBoard(canvas, board: board)
                let base = board.minY + 2
                switch kind {
                case .basil:
                    drawPotPlant(
                        canvas,
                        kind: .basil,
                        centerX: size.width * 0.5,
                        baseY: base,
                        scale: 1.15,
                        sway: sin(t * 1.5) * 0.05 + Double(pulse % 2) * 0.06,
                        highlight: true
                    )
                case .lemon:
                    drawPotPlant(
                        canvas,
                        kind: .lemon,
                        centerX: size.width * 0.5,
                        baseY: base,
                        scale: 1.15,
                        sway: sin(t * 1.2) * 0.04,
                        highlight: true
                    )
                case .bottle:
                    drawBottle(
                        canvas,
                        centerX: size.width * 0.5,
                        baseY: base,
                        tip: pulse,
                        time: t,
                        tilt: Double(dragTilt),
                        highlight: true
                    )
                }
            }
        }
        .drawingGroup()
    }
}

private func sillBoardRect(in size: CGSize) -> CGRect {
    CGRect(
        x: size.width * 0.06,
        y: size.height * 0.78,
        width: size.width * 0.88,
        height: size.height * 0.11
    )
}

private func drawBoard(_ canvas: GraphicsContext, board: CGRect) {
    var shadow = Path(roundedRect: board.offsetBy(dx: 0, dy: 3), cornerRadius: 8)
    canvas.fill(shadow, with: .color(Color.black.opacity(0.08)))

    var plank = Path(roundedRect: board, cornerRadius: 8)
    canvas.fill(plank, with: .color(Color(red: 0.45, green: 0.30, blue: 0.17)))

    for index in 0..<4 {
        let y = board.minY + board.height * (0.22 + CGFloat(index) * 0.18)
        var grain = Path()
        grain.move(to: CGPoint(x: board.minX + 8, y: y))
        grain.addLine(to: CGPoint(x: board.maxX - 8, y: y))
        canvas.stroke(
            grain,
            with: .color(Color(red: 0.32, green: 0.20, blue: 0.11).opacity(0.45)),
            lineWidth: 1
        )
    }

    var lip = Path(
        roundedRect: CGRect(
            x: board.minX - 2,
            y: board.minY - 3,
            width: board.width + 4,
            height: 7
        ),
        cornerRadius: 3
    )
    canvas.fill(lip, with: .color(Color(red: 0.58, green: 0.40, blue: 0.23)))
}

private func drawPotPlant(
    _ canvas: GraphicsContext,
    kind: BenchPotKind,
    centerX: CGFloat,
    baseY: CGFloat,
    scale: CGFloat,
    sway: Double,
    highlight: Bool
) {
    let potW: CGFloat = 54 * scale
    let potH: CGFloat = 42 * scale
    let topY = baseY - potH
    let clay = Color(red: 0.72, green: 0.32, blue: 0.24)
    let clayDeep = Color(red: 0.52, green: 0.20, blue: 0.15)
    let soil = Color(red: 0.16, green: 0.12, blue: 0.08)

    var saucer = Path(
        ellipseIn: CGRect(x: centerX - potW * 0.55, y: baseY - 6, width: potW * 1.1, height: 10)
    )
    canvas.fill(saucer, with: .color(clayDeep.opacity(0.9)))

    var pot = Path()
    pot.move(to: CGPoint(x: centerX - potW * 0.42, y: topY + 6))
    pot.addLine(to: CGPoint(x: centerX - potW * 0.32, y: baseY - 4))
    pot.addQuadCurve(
        to: CGPoint(x: centerX + potW * 0.32, y: baseY - 4),
        control: CGPoint(x: centerX, y: baseY + 2)
    )
    pot.addLine(to: CGPoint(x: centerX + potW * 0.42, y: topY + 6))
    pot.closeSubpath()
    canvas.fill(pot, with: .color(clay))

    var rim = Path(
        roundedRect: CGRect(x: centerX - potW * 0.48, y: topY, width: potW * 0.96, height: 9),
        cornerRadius: 4
    )
    canvas.fill(rim, with: .color(Color(red: 0.80, green: 0.44, blue: 0.34)))

    var soilPath = Path(
        ellipseIn: CGRect(x: centerX - potW * 0.36, y: topY + 4, width: potW * 0.72, height: 10)
    )
    canvas.fill(soilPath, with: .color(soil))

    let plantOrigin = CGPoint(x: centerX, y: topY + 2)
    canvas.drawLayer { layer in
        layer.translateBy(x: plantOrigin.x, y: plantOrigin.y)
        layer.rotate(by: .radians(sway))
        layer.translateBy(x: -plantOrigin.x, y: -plantOrigin.y)
        if kind == .basil {
            drawBasilCanopy(layer, origin: plantOrigin, scale: scale, lit: highlight)
        } else {
            drawLemonCanopy(layer, origin: plantOrigin, scale: scale, lit: highlight)
        }
    }
}

private func drawBasilCanopy(_ canvas: GraphicsContext, origin: CGPoint, scale: CGFloat, lit: Bool) {
    let leaf = Color(red: 0.20, green: 0.46, blue: 0.18)
    let leafLit = Color(red: 0.30, green: 0.56, blue: 0.24)
    let stem = Color(red: 0.28, green: 0.22, blue: 0.10)

    for row in 0..<5 {
        let y = origin.y - CGFloat(14 + row * 11) * scale
        let count = row < 3 ? 4 : 3
        for i in 0..<count {
            let spread = CGFloat(count - 1) * 0.5
            let x = origin.x + (CGFloat(i) - spread) * 14 * scale
            var stick = Path()
            stick.move(to: origin)
            stick.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: (origin.x + x) / 2, y: y + 10))
            canvas.stroke(stick, with: .color(stem), style: StrokeStyle(lineWidth: 1.4 * scale, lineCap: .round))

            let blade = leafPath(
                center: CGPoint(x: x, y: y - 2),
                length: 16 * scale,
                width: 8 * scale,
                angle: .degrees(Double(i - count / 2) * 18 - 90)
            )
            canvas.fill(blade, with: .color((i + row).isMultiple(of: 2) || lit ? leafLit : leaf))
        }
    }
}

private func drawLemonCanopy(_ canvas: GraphicsContext, origin: CGPoint, scale: CGFloat, lit: Bool) {
    let bark = Color(red: 0.36, green: 0.24, blue: 0.14)
    let leaf = Color(red: 0.16, green: 0.40, blue: 0.15)
    let leafLit = Color(red: 0.26, green: 0.50, blue: 0.20)
    let citrus = Color(red: 0.90, green: 0.72, blue: 0.18)

    var trunk = Path()
    trunk.move(to: origin)
    trunk.addLine(to: CGPoint(x: origin.x, y: origin.y - 58 * scale))
    canvas.stroke(trunk, with: .color(bark), style: StrokeStyle(lineWidth: 3.2 * scale, lineCap: .round))

    let branches: [(CGPoint, CGFloat)] = [
        (CGPoint(x: origin.x + 22 * scale, y: origin.y - 42 * scale), 35),
        (CGPoint(x: origin.x - 20 * scale, y: origin.y - 36 * scale), -40),
        (CGPoint(x: origin.x + 8 * scale, y: origin.y - 54 * scale), 12),
    ]
    for branch in branches {
        var arm = Path()
        arm.move(to: CGPoint(x: origin.x, y: origin.y - 28 * scale))
        arm.addLine(to: branch.0)
        canvas.stroke(arm, with: .color(bark), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
    }

    let leaves: [(CGFloat, CGFloat)] = [
        (-18, -48), (16, -52), (-6, -62), (24, -38),
        (-24, -34), (4, -70), (14, -64), (-14, -58),
    ]
    for (index, offset) in leaves.enumerated() {
        let placed = CGPoint(
            x: origin.x + offset.0 * scale,
            y: origin.y + offset.1 * scale
        )
        let blade = leafPath(
            center: placed,
            length: 15 * scale,
            width: 7 * scale,
            angle: .degrees(Double(index) * 28 - 70)
        )
        canvas.fill(blade, with: .color(index.isMultiple(of: 2) || lit ? leafLit : leaf))
    }

    let fruits = [
        CGPoint(x: origin.x + 18 * scale, y: origin.y - 30 * scale),
        CGPoint(x: origin.x - 16 * scale, y: origin.y - 26 * scale),
        CGPoint(x: origin.x + 4 * scale, y: origin.y - 40 * scale),
    ]
    for (index, fruit) in fruits.enumerated() {
        let r: CGFloat = (index == 0 ? 8 : 6.5) * scale
        var oval = Path(ellipseIn: CGRect(x: fruit.x - r * 0.85, y: fruit.y - r, width: r * 1.7, height: r * 2.1))
        canvas.fill(oval, with: .color(citrus))
        var shine = Path(ellipseIn: CGRect(x: fruit.x - r * 0.25, y: fruit.y - r * 0.55, width: r * 0.45, height: r * 0.55))
        canvas.fill(shine, with: .color(Color.white.opacity(0.35)))
    }
}

private func drawBottle(
    _ canvas: GraphicsContext,
    centerX: CGFloat,
    baseY: CGFloat,
    tip: Int,
    time: TimeInterval,
    tilt: Double = 0,
    highlight: Bool
) {
    let pulseTilt = tip == 0 ? sin(time * 0.7) * 0.03 : (tip.isMultiple(of: 2) ? 0.16 : 0.48)
    let pour = max(tilt, pulseTilt)
    let origin = CGPoint(x: centerX, y: baseY - 8)

    canvas.drawLayer { layer in
        layer.translateBy(x: origin.x, y: origin.y)
        layer.rotate(by: .radians(pour))
        layer.translateBy(x: -origin.x, y: -origin.y)

        let body = Color(red: 0.10, green: 0.34, blue: 0.18)
        let label = Color(red: 0.90, green: 0.82, blue: 0.42)
        let cap = Color(red: 0.90, green: 0.86, blue: 0.78)

        var bottle = Path(
            roundedRect: CGRect(x: centerX - 12, y: baseY - 78, width: 24, height: 62),
            cornerRadius: 8
        )
        layer.fill(bottle, with: .color(body))

        var shoulder = Path(ellipseIn: CGRect(x: centerX - 12, y: baseY - 86, width: 24, height: 16))
        layer.fill(shoulder, with: .color(body))

        var neck = Path(roundedRect: CGRect(x: centerX - 5, y: baseY - 100, width: 10, height: 18), cornerRadius: 3)
        layer.fill(neck, with: .color(Color(red: 0.55, green: 0.72, blue: 0.52)))

        var lid = Path(roundedRect: CGRect(x: centerX - 7, y: baseY - 108, width: 14, height: 10), cornerRadius: 3)
        layer.fill(lid, with: .color(cap))

        var band = Path(roundedRect: CGRect(x: centerX - 10, y: baseY - 58, width: 20, height: 18), cornerRadius: 3)
        layer.fill(band, with: .color(label))

        if highlight || tilt > 0.05 {
            var glow = Path(ellipseIn: CGRect(x: centerX - 4, y: baseY - 72, width: 6, height: 18))
            layer.fill(glow, with: .color(Color.white.opacity(0.22)))
        }
    }
}

private func drawFallingDrop(_ canvas: GraphicsContext, board: CGRect, token: Int, time: TimeInterval) {
    let phase = (time * 1.6 + Double(token) * 0.37).truncatingRemainder(dividingBy: 1.4)
    guard phase < 1.0 else { return }
    let x = board.minX + board.width * 0.34 - CGFloat(phase) * 18
    let y = board.minY - 90 + CGFloat(phase) * 95
    let drop = Color(red: 0.32, green: 0.56, blue: 0.72)
    var path = Path(ellipseIn: CGRect(x: x, y: y, width: 7, height: 11))
    canvas.fill(path, with: .color(drop.opacity(1 - phase * 0.7)))
}

private func leafPath(center: CGPoint, length: CGFloat, width: CGFloat, angle: Angle) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 0, y: -length / 2))
    path.addQuadCurve(to: CGPoint(x: 0, y: length / 2), control: CGPoint(x: width / 2, y: 0))
    path.addQuadCurve(to: CGPoint(x: 0, y: -length / 2), control: CGPoint(x: -width / 2, y: 0))
    path.closeSubpath()

    let transform = CGAffineTransform(translationX: center.x, y: center.y)
        .rotated(by: CGFloat(angle.radians))
    return path.applying(transform)
}
