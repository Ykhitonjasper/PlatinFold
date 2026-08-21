import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    Capsule()
                        .fill(isSelected ? AppTheme.accent : AppTheme.bgElevated)
                        .shadow(
                            color: isSelected ? AppTheme.accent.opacity(0.22) : .clear,
                            radius: 10,
                            x: 0,
                            y: 4
                        )
                }
                .overlay {
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : AppTheme.hairline,
                            lineWidth: AppMetrics.hairlineWidth
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct TagChip: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppTheme.textMono)
        .pillSurface()
        .accessibilityElement(children: .combine)
    }
}

struct ChipRow<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                content
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    ScreenScaffold {
        ChipRow {
            FilterChip(title: "All", isSelected: true) {}
            FilterChip(title: "Cold", isSelected: false) {}
            FilterChip(title: "Hot", isSelected: false) {}
        }
        TagChip(title: "Coarse grind", systemImage: "circle.grid.2x2")
    }
}
