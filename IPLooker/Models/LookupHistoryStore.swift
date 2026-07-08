import Foundation

// MARK: - LookupHistoryEntry

struct LookupHistoryEntry: Identifiable, Hashable {
    let id: UUID = .init()
    let ip: String
}

// MARK: - LookupHistoryStore

@MainActor
@Observable
final class LookupHistoryStore {
    private(set) var entries: [LookupHistoryEntry] = []
    private(set) var currentIndex: Int? = nil

    var canGoBack: Bool {
        guard let currentIndex else { return false }
        return currentIndex > self.entries.startIndex
    }

    var canGoForward: Bool {
        guard let currentIndex else { return false }
        return currentIndex < self.entries.index(before: self.entries.endIndex)
    }

    var currentIP: String? {
        guard let currentIndex, self.entries.indices.contains(currentIndex) else { return nil }
        return self.entries[currentIndex].ip
    }

    func recordLookup(_ ip: String) {
        if let currentIP, currentIP == ip {
            return
        }

        if let currentIndex, currentIndex < self.entries.index(before: self.entries.endIndex) {
            self.entries.removeSubrange(self.entries.index(after: currentIndex) ..< self.entries.endIndex)
        }

        self.entries.append(.init(ip: ip))
        self.currentIndex = self.entries.index(before: self.entries.endIndex)
    }

    func goBack() -> String? {
        guard self.canGoBack, let currentIndex else { return nil }
        let newIndex = self.entries.index(before: currentIndex)
        self.currentIndex = newIndex
        return self.entries[newIndex].ip
    }

    func goForward() -> String? {
        guard self.canGoForward, let currentIndex else { return nil }
        let newIndex = self.entries.index(after: currentIndex)
        self.currentIndex = newIndex
        return self.entries[newIndex].ip
    }

    func selectEntry(id: LookupHistoryEntry.ID) -> String? {
        guard let index = self.entries.firstIndex(where: { $0.id == id }) else { return nil }
        self.currentIndex = index
        return self.entries[index].ip
    }

    func clear() {
        self.entries.removeAll()
        self.currentIndex = nil
    }
}
