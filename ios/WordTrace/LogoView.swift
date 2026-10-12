import SwiftUI

struct LogoView: View {
    var side: CGFloat = 36

    var body: some View {
        Canvas { context, size in
            let s = size.width / 36
            let rect = CGRect(origin: .zero, size: size)
            context.fill(
                Path(roundedRect: rect, cornerRadius: 10 * s, style: .continuous),
                with: .color(Color(hex: 0x3B3BD6))
            )
            var path = Path()
            path.move(to: CGPoint(x: 10 * s, y: 10 * s))
            path.addLine(to: CGPoint(x: 26 * s, y: 10 * s))
            path.addLine(to: CGPoint(x: 26 * s, y: 18 * s))
            path.addLine(to: CGPoint(x: 10 * s, y: 18 * s))
            path.addLine(to: CGPoint(x: 10 * s, y: 26 * s))
            path.addLine(to: CGPoint(x: 26 * s, y: 26 * s))
            context.stroke(
                path,
                with: .color(Color(hex: 0xFFD36B)),
                style: StrokeStyle(lineWidth: 4 * s, lineCap: .round, lineJoin: .round)
            )
            context.fill(Path(ellipseIn: CGRect(x: 7 * s, y: 7 * s, width: 6 * s, height: 6 * s)), with: .color(.white))
            context.fill(Path(ellipseIn: CGRect(x: 23 * s, y: 23 * s, width: 6 * s, height: 6 * s)), with: .color(.white))
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}
