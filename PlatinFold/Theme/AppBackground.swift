import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.bgBase

            LinearGradient(
                colors: [
                    Color.white.opacity(0.72),
                    AppTheme.bgBase.opacity(0.2),
                    .clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [AppTheme.backgroundGlow.opacity(0.7), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 460
            )

            RadialGradient(
                colors: [AppTheme.accent.opacity(0.06), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
