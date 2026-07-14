import Foundation
import CloudKit

@Observable
final class CloudKitService {
    private let container = CKContainer.default()
    private let database = CKContainer.default().privateCloudDatabase
    private let recordType = "ClipItem"

    var isSyncing = false
    var lastSyncDate: Date?
    var errorMessage: String?

    private let store = ClipboardStore.shared

    func sync(completion: @escaping () -> Void = {}) {
        guard !isSyncing else { completion(); return }
        isSyncing = true
        errorMessage = nil

        let group = DispatchGroup()

        var pushError: Error?
        var pullError: Error?

        group.enter()
        pushLocalChanges { error in
            pushError = error
            group.leave()
        }

        group.enter()
        pullRemoteChanges { error in
            pullError = error
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.isSyncing = false
            self?.lastSyncDate = Date()
            if let error = pushError ?? pullError {
                self?.errorMessage = error.localizedDescription
            }
            completion()
        }
    }

    // MARK: - Push

    private func pushLocalChanges(completion: @escaping (Error?) -> Void) {
        let items = store.allItems.filter { $0.isPinned }
        guard !items.isEmpty else { completion(nil); return }

        let records = items.compactMap { item -> CKRecord? in
            let recordID = CKRecord.ID(recordName: item.id.uuidString)
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record["content"] = item.content as CKRecordValue
            record["type"] = item.type.rawValue as CKRecordValue
            record["timestamp"] = item.timestamp as CKRecordValue
            record["isPinned"] = item.isPinned as CKRecordValue
            return record
        }

        let operation = CKModifyRecordsOperation(recordsToSave: records)
        operation.savePolicy = .ifServerRecordUnchanged
        operation.modifyRecordsCompletionBlock = { _, _, error in
            completion(error)
        }
        database.add(operation)
    }

    // MARK: - Pull

    private func pullRemoteChanges(completion: @escaping (Error?) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        database.fetch(withQuery: query) { [weak self] result in
            switch result {
            case .success((let matchResults, _)):
                let records = matchResults.compactMap { try? $0.1.get() }
                let items = records.compactMap { self?.recordToItem($0) }
                for item in items {
                    if !ClipboardStore.shared.hasItem(item.content) || item.isPinned {
                        ClipboardStore.shared.insert(item)
                    }
                }
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    private func recordToItem(_ record: CKRecord) -> ClipItem? {
        guard let content = record["content"] as? String,
              let typeRaw = record["type"] as? String,
              let timestamp = record["timestamp"] as? Date
        else { return nil }

        let type = ClipType(rawValue: typeRaw) ?? .text
        let isPinned = (record["isPinned"] as? Bool) ?? false

        return ClipItem(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            content: content,
            type: type,
            timestamp: timestamp,
            isPinned: isPinned
        )
    }

    func enableAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
