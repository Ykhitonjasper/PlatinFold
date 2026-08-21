import SwiftUI

enum AppMetrics {
    static let screenPadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 22
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 22
    static let contentSpacing: CGFloat = 14
    static let tightSpacing: CGFloat = 6
    static let hairlineWidth: CGFloat = 0.75
    static let iconColumn: CGFloat = 28
    static let tileMinWidth: CGFloat = 150
    static let controlRadius: CGFloat = 14
    static let inputVerticalPadding: CGFloat = 15
    static let segmentVerticalPadding: CGFloat = 10
    static let readoutAccentWidth: CGFloat = 3
    static let readoutPadding: CGFloat = 22
    static let readoutValueSize: CGFloat = 48
    static let buttonRadius: CGFloat = 16
}

extension View {
    func cardSurface(
        padding: CGFloat = AppMetrics.cardPadding,
        radius: CGFloat = AppMetrics.cardRadius
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape
                    .fill(AppTheme.bgElevated)
                    .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 8)
                    .shadow(color: AppTheme.accent.opacity(0.04), radius: 28, x: 0, y: 12)
            }
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            AppTheme.hairline.opacity(0.85),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppMetrics.hairlineWidth
                )
            }
    }

    func pillSurface() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.bgElevated.opacity(0.92), in: Capsule())
            .overlay {
                Capsule().stroke(AppTheme.hairline.opacity(0.9), lineWidth: AppMetrics.hairlineWidth)
            }
    }
}

#Preview {
    VStack(spacing: AppMetrics.sectionSpacing) {
        Text("Elevated block")
            .foregroundStyle(AppTheme.textPrimary)
            .cardSurface()
        Text("Compact tag")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
            .pillSurface()
    }
    .padding(AppMetrics.screenPadding)
    .background(AppBackground())
}
