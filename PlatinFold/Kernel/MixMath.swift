import Foundation

enum MixMath {
    static func parse(_ text: String) -> Double? {
        let trimmed = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return Double(trimmed)
    }

    static func number(_ value: Double, digits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = digits
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func ml(_ value: Double) -> String {
        "\(number(value, digits: 1)) ml"
    }

    static func liters(_ value: Double) -> String {
        "\(number(value, digits: 2)) L"
    }

    static func grams(_ value: Double) -> String {
        "\(number(value, digits: 1)) g"
    }

    static func ratio(water: Double, tea: Double) -> String {
        "\(number(water, digits: 0)):\(number(tea, digits: 0))"
    }

    static func rateMl(_ value: Double) -> String {
        "\(number(value, digits: 2)) ml/L"
    }

    static func rateGrams(_ value: Double) -> String {
        "\(number(value, digits: 2)) g/L"
    }

    static func pots(_ value: Double) -> String {
        let count = Int(value.rounded())
        return count == 1 ? "1 pot" : "\(count) pots"
    }

    static func tankLine(liters: Double, rate: Double) -> String {
        "\(self.liters(liters)) at \(rateMl(rate))"
    }

    static func clampPositive(_ value: Double) -> Double {
        max(value, 0)
    }

    static func passLabel(_ multiplier: Double) -> String {
        "\(number(multiplier, digits: 0))×"
    }

    static func cutLabel(_ fraction: Double) -> String {
        if fraction <= 0.3 { return "Quarter" }
        return "Half"
    }

    static func diameterLabel(_ cm: Double) -> String {
        "\(number(cm, digits: 0)) cm"
    }

    static func areaLabel(_ m2: Double) -> String {
        "\(number(m2, digits: 3)) m²"
    }

    static func weekLabel(_ weeks: Double) -> String {
        let count = Int(weeks.rounded())
        return count == 1 ? "1 week" : "\(count) weeks"
    }
}

enum MixDate {
    static func day(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: iso) ?? Date(timeIntervalSince1970: 1_500_000_000)
    }

    static func short(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
