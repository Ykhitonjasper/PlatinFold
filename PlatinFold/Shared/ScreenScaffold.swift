import SwiftUI

struct ScreenScaffold<Content: View>: View {
    private let spacing: CGFloat
    private let scrolls: Bool
    private let content: Content

    init(
        spacing: CGFloat = AppMetrics.sectionSpacing,
        scrolls: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.scrolls = scrolls
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackground()

            if scrolls {
                ScrollView {
                    stack
                }
            } else {
                stack
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var stack: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(AppMetrics.screenPadding)
    }
}

struct ScreenHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .tracking(-0.4)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScreenScaffold {
        ScreenHeader(
            title: "Preparation library",
            subtitle: "Everything worth checking before the next visit."
        )
        Text("Section body")
            .foregroundStyle(AppTheme.textPrimary)
            .cardSurface()
    }
}
