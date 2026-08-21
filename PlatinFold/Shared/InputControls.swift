import SwiftUI

struct NumberField: View {
    let title: String
    @Binding private var value: String
    var unit: String?
    var prompt: String?
    var help: String?
    var error: String?

    init(
        title: String,
        value: Binding<String>,
        unit: String? = nil,
        prompt: String? = nil,
        help: String? = nil,
        error: String? = nil
    ) {
        self.title = title
        _value = value
        self.unit = unit
        self.prompt = prompt
        self.help = help
        self.error = error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.tightSpacing) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer(minLength: 0)

                if let unit {
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textMono)
                }
            }

            TextField(prompt ?? title, text: $value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, AppMetrics.cardPadding)
                .padding(.vertical, AppMetrics.inputVerticalPadding)
                .background(AppTheme.bgBase.opacity(0.72), in: RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                        .stroke(error == nil ? AppTheme.hairline : AppTheme.danger, lineWidth: AppMetrics.hairlineWidth)
                }
                .accessibilityLabel(title)
                .accessibilityHint(help ?? "")

            if let help, error == nil {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let error {
                InlineError(message: error)
            }
        }
    }
}

struct SegmentOption: Identifiable, Hashable {
    let id: String
    let title: String

    init(_ title: String, id: String? = nil) {
        self.id = id ?? title
        self.title = title
    }
}

struct SegmentedPicker: View {
    let title: String
    let options: [SegmentOption]
    @Binding private var selection: String
    var help: String?

    init(
        title: String,
        options: [SegmentOption],
        selection: Binding<String>,
        help: String? = nil
    ) {
        self.title = title
        self.options = options
        _selection = selection
        self.help = help
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: AppMetrics.tightSpacing) {
                ForEach(options) { option in
                    Button {
                        selection = option.id
                    } label: {
                        Text(option.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selection == option.id ? AppTheme.bgBase : AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppMetrics.segmentVerticalPadding)
                            .background(
                                selection == option.id ? AppTheme.accent : AppTheme.bgElevated,
                                in: RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                                    .stroke(AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityHint(help ?? "")
                    .accessibilityAddTraits(selection == option.id ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

struct InlineError: View {
    let message: String
    var systemImage = "exclamationmark.triangle.fill"

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.danger)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    InputControlsPreview()
}

private struct InputControlsPreview: View {
    @State private var distance = "18.5"
    @State private var unit = "metric"

    var body: some View {
        ScreenScaffold {
            NumberField(
                title: "Baseline distance",
                value: $distance,
                unit: "m",
                prompt: "0.0",
                help: "Measure from the same starting point."
            )

            SegmentedPicker(
                title: "Units",
                options: [SegmentOption("Metric", id: "metric"), SegmentOption("Imperial", id: "imperial")],
                selection: $unit
            )

            InlineError(message: "Enter a value greater than zero.")
        }
    }
}
