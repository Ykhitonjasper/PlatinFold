import SwiftUI

struct MixCover: View {
    private let bench = BenchSeed.seedBenches[0]

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                    ScreenHeader(
                        title: bench.name,
                        subtitle: "\(AppTheme.displayName) · exact dose for this sill"
                    )

                    TileGrid {
                        MetricTile(
                            title: "Pots",
                            value: "\(bench.potCount)",
                            caption: bench.location,
                            systemImage: "square.grid.3x3"
                        )
                        MetricTile(
                            title: "Tank",
                            value: "4 L",
                            caption: "Ready on the sill",
                            systemImage: "drop.halffull"
                        )
                        MetricTile(
                            title: "Last mix",
                            value: "2 ml/L",
                            caption: "FloraGro dilute",
                            systemImage: "leaf"
                        )
                        MetricTile(
                            title: "Saved lines",
                            value: "6",
                            caption: "On this bench",
                            systemImage: "tray.full"
                        )
                    }

                    SectionCard(
                        title: "Quick tools",
                        footnote: "Local mixes stored on this iPhone."
                    ) {
                        VStack(spacing: AppMetrics.contentSpacing) {
                            toolRow(title: "Dilute bottle", detail: "2 ml/L in 4 L tank", symbol: "drop.halffull")
                            toolRow(title: "Per-pot pour", detail: "120 ml per 18 cm pot", symbol: "cup.and.saucer")
                            toolRow(title: "Weekly feed", detail: "Thursday · balcony rack", symbol: "calendar")
                        }
                    }
                }
                .padding(AppMetrics.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(AppTheme.displayName) workspace")
    }

    private func toolRow(title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: AppMetrics.contentSpacing) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    MixCover()
}
