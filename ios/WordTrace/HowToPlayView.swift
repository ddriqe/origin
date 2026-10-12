import SwiftUI

struct HowToPlayView: View {
    var onClose: () -> Void

    private let rules = [
        "Drag through neighbouring letters: up, down, left, or right. Not diagonally, and not through walls.",
        "Every open tile belongs to one word. The rows show those lengths, shortest first.",
        "A miss flashes as a dashed line, then clears on its own.",
        "Hint reveals the next letter. The arrows replay earlier days.",
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to play")
                            .font(Theme.outfit(22, "Outfit-ExtraBold"))
                            .foregroundStyle(Theme.ink)
                        Text("Trace every hidden word and cover the whole board.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.stone500)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.stone500)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Close")
                }

                MiniExample()

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rules, id: \.self) { rule in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(rule)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                    }
                }

                Button(action: onClose) {
                    Text("Let's play")
                        .font(Theme.outfit(17, "Outfit-Bold"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.indigo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)
        }
    }
}

/// A 3×3 example: CAT bends around a wall and SUN winds through the rest.
private struct MiniExample: View {
    private let cells: [(String, Int)] = [
        ("C", 0), ("A", 0), ("#", -1),
        ("#", -1), ("T", 0), ("S", 1),
        ("#", -1), ("N", 1), ("U", 1),
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 4), count: 3), spacing: 4) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    if cell.0 == "#" {
                        WallSwatch()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        Text(cell.0)
                            .font(Theme.outfit(16, "Outfit-Bold"))
                            .frame(width: 36, height: 36)
                            .background(cell.1 == 0 ? Color(hex: 0xCFE8FF) : Color(hex: 0xFFE1C2))
                            .foregroundStyle(cell.1 == 0 ? Color(hex: 0x0B3A66) : Color(hex: 0x6B3300))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("CAT bends down around the wall.")
                    .foregroundStyle(Color(hex: 0x0B3A66))
                Text("SUN winds through what's left.")
                    .foregroundStyle(Color(hex: 0x6B3300))
                Text("Every tile used once, so it's solved.")
                    .foregroundStyle(Theme.stone500)
            }
            .font(.caption)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xF5F5F4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WallSwatch: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.wallDark))
            var start: CGFloat = -size.height
            while start < size.width + size.height {
                var band = Path()
                band.move(to: CGPoint(x: start, y: 0))
                band.addLine(to: CGPoint(x: start + size.height, y: size.height))
                band.addLine(to: CGPoint(x: start + size.height + 3, y: size.height))
                band.addLine(to: CGPoint(x: start + 3, y: 0))
                band.closeSubpath()
                context.fill(band, with: .color(Theme.wallLight))
                start += 6
            }
        }
    }
}
