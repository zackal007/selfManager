import SwiftUI

struct MasonrySpanKey: LayoutValueKey {
    static let defaultValue: Int = 1
}

// 允许为每个子视图提供一个固定高度，优先于 sizeThatFits
struct MasonryHeightKey: LayoutValueKey {
    static let defaultValue: CGFloat = 0
}

extension View {
    func masonrySpan(_ span: Int) -> some View {
        self.layoutValue(key: MasonrySpanKey.self, value: max(1, span))
    }
}

struct MasonryLayout: Layout {
    var spacing: CGFloat = 16
    var minColumnWidth: CGFloat = 320
    var horizontalPadding: CGFloat = 0

    private func columns(for totalWidth: CGFloat) -> Int {
        guard totalWidth > 0 else { return 2 }
        let available = totalWidth - horizontalPadding * 2
        let col = Int((available + spacing) / (minColumnWidth + spacing))
        return max(2, col)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        let cols = columns(for: width)
        let colWidth = (width - horizontalPadding * 2 - CGFloat(cols - 1) * spacing) / CGFloat(cols)
        var columnHeights = Array(repeating: CGFloat(0), count: cols)
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let span = min(max(1, subview[MasonrySpanKey.self]), cols)
            let itemWidth = colWidth * CGFloat(span) + spacing * CGFloat(span - 1)
            // 如果提供了固定高度，直接使用该高度
            let overrideHeight = subview[MasonryHeightKey.self]
            let size: CGSize = {
                if overrideHeight > 0 {
                    return CGSize(width: itemWidth, height: overrideHeight)
                } else {
                    return subview.sizeThatFits(.init(width: itemWidth, height: nil))
                }
            }()
            if span == 1 {
                let idx = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
                columnHeights[idx] += size.height + spacing
                maxHeight = max(maxHeight, columnHeights[idx])
            } else {
                var bestIndex = 0
                var bestTop = CGFloat.greatestFiniteMagnitude
                for i in 0..<(cols - span + 1) {
                    let top = (i..<(i+span)).map { columnHeights[$0] }.max() ?? 0
                    if top < bestTop {
                        bestTop = top
                        bestIndex = i
                    }
                }
                let newHeight = bestTop + size.height + spacing
                for i in bestIndex..<(bestIndex + span) {
                    columnHeights[i] = newHeight
                }
                maxHeight = max(maxHeight, newHeight)
            }
        }
        if maxHeight > 0 { maxHeight -= spacing }
        return CGSize(width: width, height: maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let width = bounds.width
        let cols = columns(for: width)
        let colWidth = (width - horizontalPadding * 2 - CGFloat(cols - 1) * spacing) / CGFloat(cols)
        var columnHeights = Array(repeating: CGFloat(0), count: cols)

        for subview in subviews {
            let span = min(max(1, subview[MasonrySpanKey.self]), cols)
            let itemWidth = colWidth * CGFloat(span) + spacing * CGFloat(span - 1)
            // 如果提供了固定高度，直接使用该高度
            let overrideHeight = subview[MasonryHeightKey.self]
            let size: CGSize = {
                if overrideHeight > 0 {
                    return CGSize(width: itemWidth, height: overrideHeight)
                } else {
                    return subview.sizeThatFits(.init(width: itemWidth, height: nil))
                }
            }()
            if span == 1 {
                let idx = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
                let x = bounds.minX + horizontalPadding + CGFloat(idx) * (colWidth + spacing)
                let y = bounds.minY + columnHeights[idx]
                subview.place(at: CGPoint(x: x, y: y), proposal: .init(width: itemWidth, height: size.height))
                columnHeights[idx] += size.height + spacing
            } else {
                var bestIndex = 0
                var bestTop = CGFloat.greatestFiniteMagnitude
                for i in 0..<(cols - span + 1) {
                    let top = (i..<(i+span)).map { columnHeights[$0] }.max() ?? 0
                    if top < bestTop {
                        bestTop = top
                        bestIndex = i
                    }
                }
                let x = bounds.minX + horizontalPadding + CGFloat(bestIndex) * (colWidth + spacing)
                let y = bounds.minY + bestTop
                subview.place(at: CGPoint(x: x, y: y), proposal: .init(width: itemWidth, height: size.height))
                let newHeight = bestTop + size.height + spacing
                for i in bestIndex..<(bestIndex + span) {
                    columnHeights[i] = newHeight
                }
            }
        }
    }
}