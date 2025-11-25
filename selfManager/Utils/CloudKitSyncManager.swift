import Foundation
import CloudKit
import SwiftData

@MainActor
final class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()
    @Published var accountAvailable = false
    @Published var syncing = false
    @Published var lastSyncDate: Date?
    private let container = CKContainer(identifier: "iCloud.zack.selfManager")
    private let privateDB: CKDatabase

    private init() {
        privateDB = container.privateCloudDatabase
    }

    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            accountAvailable = (status == .available)
        } catch {
            accountAvailable = false
        }
    }

    func startSync(modelContext: ModelContext) async {
        guard accountAvailable else { return }
        syncing = true
        await exportGoals(modelContext: modelContext)
        await exportRecords(modelContext: modelContext)
        await exportContacts(modelContext: modelContext)
        await importGoals(modelContext: modelContext)
        await importRecords(modelContext: modelContext)
        await importContacts(modelContext: modelContext)
        lastSyncDate = Date()
        syncing = false
    }

    private func exportGoals(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Goal>()
        let goals = (try? modelContext.fetch(descriptor)) ?? []
        for goal in goals {
            let recordID = CKRecord.ID(recordName: goal.id.uuidString)
            let record = CKRecord(recordType: "Goal", recordID: recordID)
            record["name"] = goal.name as CKRecordValue
            record["description"] = goal.goalDescription as CKRecordValue
            record["progress"] = goal.progress as CKRecordValue
            record["modifyTime"] = goal.modifyTime as CKRecordValue
            do { _ = try await privateDB.save(record) } catch { continue }
        }
    }

    private func importGoals(modelContext: ModelContext) async {
        let query = CKQuery(recordType: "Goal", predicate: NSPredicate(value: true))
        do {
            let result = try await privateDB.records(matching: query)
            for (_, match) in result.matchResults {
                if let record = try? match.get() {
                    let idStr = record.recordID.recordName
                    guard let uuid = UUID(uuidString: idStr) else { continue }
                    let name = record["name"] as? String ?? ""
                    let desc = record["description"] as? String ?? ""
                    let progress = record["progress"] as? Double ?? 0.0
                    let modify = record["modifyTime"] as? Date ?? Date()
                    if let existing = try? modelContext.fetch(FetchDescriptor<Goal>(predicate: #Predicate { $0.id == uuid })).first {
                        if modify > existing.modifyTime {
                            existing.name = name
                            existing.goalDescription = desc
                            existing.progress = progress
                            existing.modifyTime = modify
                        }
                    }
                }
            }
            try? modelContext.save()
        } catch {}
    }

    private func exportRecords(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Record>()
        let records = (try? modelContext.fetch(descriptor)) ?? []
        for rec in records {
            let recordID = CKRecord.ID(recordName: rec.id.uuidString)
            let record = CKRecord(recordType: "Record", recordID: recordID)
            record["title"] = rec.title as CKRecordValue
            record["content"] = rec.content as CKRecordValue
            record["createTime"] = rec.createTime as CKRecordValue
            do { _ = try await privateDB.save(record) } catch { continue }
        }
    }

    private func importRecords(modelContext: ModelContext) async {
        let query = CKQuery(recordType: "Record", predicate: NSPredicate(value: true))
        do {
            let result = try await privateDB.records(matching: query)
            for (_, match) in result.matchResults {
                if let record = try? match.get() {
                    let idStr = record.recordID.recordName
                    guard let uuid = UUID(uuidString: idStr) else { continue }
                    let title = record["title"] as? String ?? ""
                    let content = record["content"] as? String ?? ""
                    let create = record["createTime"] as? Date ?? Date()
                    if let existing = try? modelContext.fetch(FetchDescriptor<Record>(predicate: #Predicate { $0.id == uuid })).first {
                        if create > existing.createTime {
                            existing.title = title
                            existing.content = content
                            existing.createTime = create
                        }
                    }
                }
            }
            try? modelContext.save()
        } catch {}
    }

    private func exportContacts(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Contact>()
        let contacts = (try? modelContext.fetch(descriptor)) ?? []
        for c in contacts {
            let recordID = CKRecord.ID(recordName: c.id.uuidString)
            let record = CKRecord(recordType: "Contact", recordID: recordID)
            record["name"] = c.name as CKRecordValue
            record["position"] = (c.position ?? "") as CKRecordValue
            record["modifyTime"] = c.modifyTime as CKRecordValue
            do { _ = try await privateDB.save(record) } catch { continue }
        }
    }

    private func importContacts(modelContext: ModelContext) async {
        let query = CKQuery(recordType: "Contact", predicate: NSPredicate(value: true))
        do {
            let result = try await privateDB.records(matching: query)
            for (_, match) in result.matchResults {
                if let record = try? match.get() {
                    let idStr = record.recordID.recordName
                    guard let uuid = UUID(uuidString: idStr) else { continue }
                    let name = record["name"] as? String ?? ""
                    let position = record["position"] as? String ?? ""
                    let modify = record["modifyTime"] as? Date ?? Date()
                    if let existing = try? modelContext.fetch(FetchDescriptor<Contact>(predicate: #Predicate { $0.id == uuid })).first {
                        if modify > existing.modifyTime {
                            existing.name = name
                            existing.position = position
                            existing.modifyTime = modify
                        }
                    }
                }
            }
            try? modelContext.save()
        } catch {}
    }
}