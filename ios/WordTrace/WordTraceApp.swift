import CoreText
import SwiftUI

@main
struct WordTraceApp: App {
    init() {
        OutfitFont.register()
    }

    var body: some Scene {
        WindowGroup {
            GameView()
                .tint(Theme.indigo)
        }
    }
}

enum OutfitFont {
    static func register() {
        let names = ["Outfit-Regular", "Outfit-SemiBold", "Outfit-Bold", "Outfit-ExtraBold"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
