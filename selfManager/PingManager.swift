import Foundation
import Combine

class PingManager: ObservableObject {
    static let shared = PingManager()
    @Published private(set) var pingedMap: [UUID: Date] = [:]

    private let storageKey = "pingedGoalsMap"

    private init() {
        load()
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
    }

    var latestPingedGoalID: UUID? {
        return pingedMap.sorted { $0.value > $1.value }.first?.key
    }

    // MARK: - Persistence
    private func save() {
        let encoded: [String: Double] = pingedMap.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value.timeIntervalSince1970
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
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
}