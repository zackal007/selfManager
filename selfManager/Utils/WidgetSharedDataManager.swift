import Foundation
import SwiftData
import WidgetKit

final class WidgetSharedDataManager {
    static let shared = WidgetSharedDataManager()
    private let suiteName = "group.selfmanager.widget"
    private let goalsKey = "widget_goals_count"
    private let contactsKey = "widget_contacts_count"
    private let recordsKey = "widget_records_count"

    func writeSummary(modelContext: ModelContext) {
        let goalsCount = (try? modelContext.fetch(FetchDescriptor<Goal>()).filter { !$0.isDeleted }.count) ?? 0
        let contactsCount = (try? modelContext.fetch(FetchDescriptor<Contact>()).count) ?? 0
        let recordsCount = (try? modelContext.fetch(FetchDescriptor<Record>()).count) ?? 0
        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(goalsCount, forKey: goalsKey)
            defaults.set(contactsCount, forKey: contactsKey)
            defaults.set(recordsCount, forKey: recordsKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func readSummary() -> (Int, Int, Int) {
        let defaults = UserDefaults(suiteName: suiteName)
        let goals = defaults?.integer(forKey: goalsKey) ?? 0
        let contacts = defaults?.integer(forKey: contactsKey) ?? 0
        let records = defaults?.integer(forKey: recordsKey) ?? 0
        return (goals, contacts, records)
    }
}

