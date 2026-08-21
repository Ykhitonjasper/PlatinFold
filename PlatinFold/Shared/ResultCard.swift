import SwiftUI

struct ResultLine: Identifiable {
    let id: String
    let label: String
    let value: String

    init(label: String, value: String) {
        id = label
        self.label = label
        self.value = value
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    var unit: String?
    var lines: [ResultLine] = []
    var note: String?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.textMono.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: AppMetrics.readoutAccentWidth)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.9)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(value)
                        .font(.system(size: AppMetrics.readoutValueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    if let unit {
                        Text(unit)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.textMono)
                            .padding(.bottom, 4)
                    }
                }
                .accessibilityElement(children: .combine)

                if !lines.isEmpty {
                    Divider()
                        .overlay(AppTheme.hairline.opacity(0.8))

                    VStack(spacing: 10) {
                        ForEach(lines) { line in
                            DetailRow(label: line.label, value: line.value)
                        }
                    }
                }

                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMono)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, 14)
        }
        .cardSurface(padding: AppMetrics.readoutPadding)
    }
}

#Preview {
    ScreenScaffold {
        ResultCard(
            title: "Exact dose",
            value: "8.0",
            unit: "ml",
            lines: [
                ResultLine(label: "Water", value: "4 L"),
                ResultLine(label: "Rate", value: "2 ml/L"),
            ],
            note: "4 L tank · 2 ml/L."
        )
    }
}
