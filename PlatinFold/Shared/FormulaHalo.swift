import SwiftUI

struct FormulaHalo: View {
    let pulse: Int
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let rect = proxy.frame(in: .local)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) * 0.48

            Canvas { context, size in
                let ringCount = 3
                for i in 0..<ringCount {
                    let r = radius + CGFloat(i) * 7
                    let opacity = 0.22 - Double(i) * 0.05
                    let trimStart = (phase + CGFloat(i) * 0.14).truncatingRemainder(dividingBy: 1.0)
                    let trimEnd = trimStart + 0.55

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: r,
                        startAngle: .degrees(Double(trimStart) * 360),
                        endAngle: .degrees(Double(trimEnd) * 360),
                        clockwise: false
                    )
                    context.stroke(
                        path,
                        with: .color(AppTheme.accent.opacity(opacity)),
                        style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: pulse)
    }
}

#Preview {
    ScreenScaffold {
        ResultCard(title: "Concentrate", value: "8.0", unit: "ml")
            .overlay { FormulaHalo(pulse: 0) }
    }
}
