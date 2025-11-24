import Testing
import Foundation
@testable import selfManager

struct LocalizationManagerTests {
    @Test func testLanguageSwitchUpdatesStrings() async throws {
        let manager = LocalizationManager.shared
        manager.switchLanguage(to: .english)
        #expect("settings".localized == "Settings")
        manager.switchLanguage(to: .chinese)
        #expect("settings".localized == "设置")
    }

    @Test func testPersistenceToUserDefaults() async throws {
        let manager = LocalizationManager.shared
        manager.switchLanguage(to: .english)
        let saved = UserDefaults.standard.string(forKey: "app_language")
        #expect(saved == AppLanguage.english.rawValue)
    }

    @Test func testMissingKeyFallsBackToKey() async throws {
        let key = "__missing_test_key__"
        #expect(key.localized == key)
    }
}