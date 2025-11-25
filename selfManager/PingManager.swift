import Foundation
import Combine
import WidgetKit

class PingManager: ObservableObject {
    static let shared = PingManager()
    @Published private(set) var pingedMap: [UUID: Date] = [:]
    // 联系人被 Ping 的映射
    @Published private(set) var pingedContactsMap: [UUID: Date] = [:]
    @Published private(set) var pingedGoalNames: [UUID: String] = [:]
    @Published private(set) var pingedContactNames: [UUID: String] = [:]

    private let storageKey = "pingedGoalsMap"
    private let contactsStorageKey = "pingedContactsMap"
    private let goalNamesStorageKey = "pingedGoalNamesMap"
    private let contactNamesStorageKey = "pingedContactNamesMap"

    private init() {
        load()
        loadContacts()
        loadGoalNames()
        loadContactNames()
    }

    func ping(goalID: UUID) {
        pingedMap[goalID] = Date()
        save()
    }

    func ping(goal: Goal) {
        pingedMap[goal.id] = Date()
        pingedGoalNames[goal.id] = goal.name
        save()
    }

    func unping(goalID: UUID) {
        pingedMap.removeValue(forKey: goalID)
        pingedGoalNames.removeValue(forKey: goalID)
        save()
    }

    func unping(goal: Goal) {
        unping(goalID: goal.id)
    }

    func clearAll() {
        pingedMap.removeAll()
        save()
        pingedContactsMap.removeAll()
        saveContacts()
    }

    var latestPingedGoalID: UUID? {
        return pingedMap.sorted { $0.value > $1.value }.first?.key
    }
    
    var allPingedGoalIDs: [UUID] {
        return pingedMap.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    func isPinged(goalID: UUID) -> Bool {
        return pingedMap[goalID] != nil
    }
    
    func isPinged(goal: Goal) -> Bool {
        return isPinged(goalID: goal.id)
    }

    // MARK: - 联系人 Ping 管理
    func ping(contactID: UUID) {
        pingedContactsMap[contactID] = Date()
        saveContacts()
    }

    func ping(contact: Contact) {
        pingedContactsMap[contact.id] = Date()
        pingedContactNames[contact.id] = contact.name
        saveContacts()
    }

    func unping(contactID: UUID) {
        pingedContactsMap.removeValue(forKey: contactID)
        pingedContactNames.removeValue(forKey: contactID)
        saveContacts()
    }

    var allPingedContactIDs: [UUID] {
        return pingedContactsMap.sorted { $0.value > $1.value }.map { $0.key }
    }

    func isPinged(contactID: UUID) -> Bool {
        return pingedContactsMap[contactID] != nil
    }

    // MARK: - Persistence
    private func save() {
        let encoded: [String: Double] = pingedMap.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value.timeIntervalSince1970
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
        let nameEncoded: [String: String] = pingedGoalNames.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value
        }
        UserDefaults.standard.set(nameEncoded, forKey: goalNamesStorageKey)
        syncWidgetCounts()
    }

    private func saveContacts() {
        let encoded: [String: Double] = pingedContactsMap.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value.timeIntervalSince1970
        }
        UserDefaults.standard.set(encoded, forKey: contactsStorageKey)
        let nameEncoded: [String: String] = pingedContactNames.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value
        }
        UserDefaults.standard.set(nameEncoded, forKey: contactNamesStorageKey)
        syncWidgetCounts()
    }

    private func load() {
        guard let dict = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Double] else { return }
        var map: [UUID: Date] = [:]
        for (uuidString, timestamp) in dict {
            if let id = UUID(uuidString: uuidString) {
                map[id] = Date(timeIntervalSince1970: timestamp)
            }
        }
        pingedMap = map
        syncWidgetCounts()
    }

    private func loadContacts() {
        guard let dict = UserDefaults.standard.dictionary(forKey: contactsStorageKey) as? [String: Double] else { return }
        var map: [UUID: Date] = [:]
        for (uuidString, timestamp) in dict {
            if let id = UUID(uuidString: uuidString) {
                map[id] = Date(timeIntervalSince1970: timestamp)
            }
        }
        pingedContactsMap = map
        syncWidgetCounts()
    }

    private func loadGoalNames() {
        guard let dict = UserDefaults.standard.dictionary(forKey: goalNamesStorageKey) as? [String: String] else { return }
        var map: [UUID: String] = [:]
        for (uuidString, name) in dict {
            if let id = UUID(uuidString: uuidString) {
                map[id] = name
            }
        }
        pingedGoalNames = map
    }

    private func loadContactNames() {
        guard let dict = UserDefaults.standard.dictionary(forKey: contactNamesStorageKey) as? [String: String] else { return }
        var map: [UUID: String] = [:]
        for (uuidString, name) in dict {
            if let id = UUID(uuidString: uuidString) {
                map[id] = name
            }
        }
        pingedContactNames = map
    }

    private func syncWidgetCounts() {
        let defaults = UserDefaults(suiteName: "group.selfmanager.widget")
        defaults?.set(allPingedGoalIDs.count, forKey: "widget_pinned_goals_count")
        defaults?.set(allPingedContactIDs.count, forKey: "widget_pinned_contacts_count")
        let goalNamesList = allPingedGoalIDs.compactMap { pingedGoalNames[$0] }
        let contactNamesList = allPingedContactIDs.compactMap { pingedContactNames[$0] }
        defaults?.set(goalNamesList, forKey: "widget_pinned_goals_names")
        defaults?.set(contactNamesList, forKey: "widget_pinned_contacts_names")
        WidgetCenter.shared.reloadTimelines(ofKind: "selfmanager.core")
    }
}
