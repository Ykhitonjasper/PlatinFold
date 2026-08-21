import SwiftUI

struct CTAButton: View {
    enum Emphasis {
        case primary
        case secondary
    }

    let title: String
    var systemImage: String?
    var emphasis: Emphasis = .primary
    var hint: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SoftPressStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "")
    }

    private var label: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.headline.weight(.semibold))
        }
        .foregroundStyle(emphasis == .primary ? Color.white : AppTheme.textPrimary)
        .padding(.vertical, 16)
        .padding(.horizontal, AppMetrics.cardPadding)
        .background {
            let shape = RoundedRectangle(cornerRadius: AppMetrics.buttonRadius, style: .continuous)
            if emphasis == .primary {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.accent,
                                AppTheme.accent.opacity(0.88),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppTheme.accent.opacity(0.28), radius: 16, x: 0, y: 8)
            } else {
                shape.fill(AppTheme.bgElevated)
            }
        }
        .overlay {
            if emphasis == .secondary {
                RoundedRectangle(cornerRadius: AppMetrics.buttonRadius, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
            }
        }
    }
}

#Preview {
    ScreenScaffold {
        CTAButton(title: "Save to project", systemImage: "tray.and.arrow.down") {}
        CTAButton(title: "Start over", emphasis: .secondary) {}
        CTAButton(title: "Export", isEnabled: false) {}
    }
}
