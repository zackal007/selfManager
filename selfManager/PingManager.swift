import Foundation
import Combine

class PingManager: ObservableObject {
    static let shared = PingManager()
    @Published private(set) var pingedMap: [UUID: Date] = [:]
    // 联系人被 Ping 的映射
    @Published private(set) var pingedContactsMap: [UUID: Date] = [:]

    private let storageKey = "pingedGoalsMap"
    private let contactsStorageKey = "pingedContactsMap"

    private init() {
        load()
        loadContacts()
    }

    func ping(goalID: UUID) {
        pingedMap[goalID] = Date()
        save()
    }

    func ping(goal: Goal) {
        ping(goalID: goal.id)
    }

    func unping(goalID: UUID) {
        pingedMap.removeValue(forKey: goalID)
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

    func unping(contactID: UUID) {
        pingedContactsMap.removeValue(forKey: contactID)
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
    }

    private func saveContacts() {
        let encoded: [String: Double] = pingedContactsMap.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value.timeIntervalSince1970
        }
        UserDefaults.standard.set(encoded, forKey: contactsStorageKey)
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
    }
}