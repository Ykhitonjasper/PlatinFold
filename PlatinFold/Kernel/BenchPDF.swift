import Foundation
import UIKit

enum BenchPDF {
    static func make(bench: BenchItem, lines: [MixLineItem]) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 36
            y = draw(bench.name, font: .boldSystemFont(ofSize: 18), at: 36, y: y, width: 540)
            y = draw(
                "\(bench.potCount) pots · \(bench.location)",
                font: .systemFont(ofSize: 12),
                at: 36,
                y: y + 6,
                width: 540
            )
            y = draw(bench.note, font: .systemFont(ofSize: 11), at: 36, y: y + 4, width: 540)
            y += 16
            for item in lines {
                if y > 700 {
                    ctx.beginPage()
                    y = 36
                }
                y = draw(item.title, font: .boldSystemFont(ofSize: 13), at: 36, y: y, width: 540)
                y = draw(
                    "\(item.tool.verb) · \(item.resultText)",
                    font: .systemFont(ofSize: 11),
                    at: 36,
                    y: y + 4,
                    width: 540
                )
                y = draw(
                    "\(item.potLabel) · \(MixMath.liters(item.waterLiters)) · \(MixDate.short(item.savedAt))",
                    font: .systemFont(ofSize: 10),
                    at: 36,
                    y: y + 2,
                    width: 540
                )
                y += 14
            }
        }
    }

    static func pageCount(lineCount: Int) -> Int {
        lineCount <= 18 ? 1 : 2
    }

    static func headline(_ bench: BenchItem) -> String {
        "\(bench.name) · \(bench.potCount) pots · \(bench.location)"
    }

    static func textList(bench: BenchItem, lines: [MixLineItem]) -> String {
        var rows = [bench.name, "\(bench.potCount) pots · \(bench.location)", bench.note, ""]
        for item in lines {
            rows.append(item.title)
            rows.append("\(item.tool.verb) · \(item.resultText)")
            rows.append("\(item.potLabel) · \(MixDate.short(item.savedAt))")
            rows.append("")
        }
        return rows.joined(separator: "\n")
    }

    @discardableResult
    private static func draw(_ text: String, font: UIKit.UIFont, at x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let ns = text as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
        ]
        let bound = ns.boundingRect(
            with: CGSize(width: width, height: 200),
            options: [.usesLineFragmentOrigin],
            attributes: attrs,
            context: nil
        )
        ns.draw(in: CGRect(x: x, y: y, width: width, height: ceil(bound.height)), withAttributes: attrs)
        return y + ceil(bound.height)
    }
}
