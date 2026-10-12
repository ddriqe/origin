import SwiftUI

enum Theme {
    static let background = Color(hex: 0xF6F1EA)
    static let ink = Color(hex: 0x1C1917)
    static let stone800 = Color(hex: 0x292524)
    static let stone700 = Color(hex: 0x44403C)
    static let stone500 = Color(hex: 0x78716C)
    static let stone400 = Color(hex: 0xA8A29E)
    static let stone300 = Color(hex: 0xD6D3D1)
    static let stone200 = Color(hex: 0xE7E5E4)
    static let board = Color(hex: 0xEBE5DC)
    static let indigo = Color(hex: 0x4F46E5)
    static let indigoDeep = Color(hex: 0x4338CA)
    static let traceTile = Color(hex: 0x3B3BD6)
    static let traceInk = Color.white
    static let tracePipe = Color(hex: 0x6C6CF0)
    static let missTile = Color(hex: 0xF3F0EC)
    static let missInk = Color(hex: 0x8A5A52)
    static let missPipe = Color(hex: 0xE3B7AE)
    static let amber = Color(hex: 0xFBBF24)
    static let amberInk = Color(hex: 0x451A03)
    static let hintLetter = Color(hex: 0xB45309)
    static let emerald50 = Color(hex: 0xECFDF5)
    static let emerald200 = Color(hex: 0xA7F3D0)
    static let emerald700 = Color(hex: 0x047857)
    static let emerald900 = Color(hex: 0x064E3B)
    static let wallLight = Color(hex: 0xD9D4CC)
    static let wallDark = Color(hex: 0xCFC9C0)

    static let tones: [(tile: Color, ink: Color, pipe: Color)] = [
        (Color(hex: 0xCFE8FF), Color(hex: 0x0B3A66), Color(hex: 0x7CB8F2)),
        (Color(hex: 0xFFE1C2), Color(hex: 0x6B3300), Color(hex: 0xF5A65B)),
        (Color(hex: 0xD4F2DC), Color(hex: 0x0F4D27), Color(hex: 0x6FCF8D)),
        (Color(hex: 0xF1D9FF), Color(hex: 0x4B1670), Color(hex: 0xC08AE8)),
        (Color(hex: 0xFFF1A8), Color(hex: 0x5C4A00), Color(hex: 0xE8C93A)),
        (Color(hex: 0xFFD6DC), Color(hex: 0x6E1022), Color(hex: 0xF2899A)),
        (Color(hex: 0xC9F1EE), Color(hex: 0x0B4A46), Color(hex: 0x5FCDC4)),
    ]

    static func tone(_ index: Int) -> (tile: Color, ink: Color, pipe: Color) {
        tones[index % tones.count]
    }

    static func outfit(_ size: CGFloat, _ name: String) -> Font {
        .custom(name, size: size)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
