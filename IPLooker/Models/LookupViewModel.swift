import Foundation
import PolyKit
import SwiftUI

#if os(macOS)
    import AppKit
#endif

// MARK: - LookupViewModel

@MainActor
@Observable
final class LookupViewModel {
    var ipInput = ""
    var publicIP: String? = nil
    var isLoadingPublicIP = false
    var isLookingUp = false
    var sourceResults: [SourceResult] = []
    var aggregatedResult: AggregatedResult? = nil
    var lookupIP: String? = nil
    var errorMessage: String? = nil

    private let service: IPLookupService = .shared
    private let history: LookupHistoryStore

    var hasResults: Bool {
        self.aggregatedResult != nil
    }

    var historyEntries: [LookupHistoryEntry] {
        self.history.entries
    }

    var canGoBack: Bool {
        self.history.canGoBack
    }

    var canGoForward: Bool {
        self.history.canGoForward
    }

    var hasHistory: Bool {
        !self.history.entries.isEmpty
    }

    init(history: LookupHistoryStore = .init()) {
        self.history = history
    }

    func fetchPublicIP() async {
        guard !self.isLoadingPublicIP else { return }
        self.isLoadingPublicIP = true
        defer { isLoadingPublicIP = false }

        self.publicIP = await self.service.fetchPublicIP()
    }

    func performLookup() async {
        await self.performLookup(recordInHistory: true)
    }

    func refreshLookup() async {
        let ip = self.lookupIP ?? self.ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }
        self.ipInput = ip
        await self.performLookup(recordInHistory: false)
    }

    func goBack() async {
        guard let ip = self.history.goBack() else { return }
        self.ipInput = ip
        await self.performLookup(recordInHistory: false)
    }

    func goForward() async {
        guard let ip = self.history.goForward() else { return }
        self.ipInput = ip
        await self.performLookup(recordInHistory: false)
    }

    func selectHistoryEntry(_ entry: LookupHistoryEntry) async {
        guard let ip = self.history.selectEntry(id: entry.id) else { return }
        self.ipInput = ip
        await self.performLookup(recordInHistory: false)
    }

    func clearHistory() {
        self.history.clear()
    }

    func checkClipboardForIP() async {
        #if os(macOS)
            guard let string = NSPasteboard.general.string(forType: .string) else { return }
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard self.isValidIP(trimmed) else { return }
            logger.info("Clipboard contains IP address \(trimmed), auto-filling and running lookup")
            self.ipInput = trimmed
            await self.performLookup()
        #else
            // iOS uses the system Paste button instead of auto-reading the clipboard.
            return
        #endif
    }

    func lookupMyIP() async {
        guard let publicIP else { return }
        self.ipInput = publicIP
        await self.performLookup()
    }

    func clear() {
        self.sourceResults = []
        self.aggregatedResult = nil
        self.lookupIP = nil
        self.errorMessage = nil
        self.ipInput = ""
    }

    private func performLookup(recordInHistory: Bool) async {
        let ip = self.ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else {
            self.errorMessage = "Please enter an IP address."
            return
        }
        guard self.isValidIP(ip) else {
            self.errorMessage = "Invalid IP address format."
            return
        }

        self.errorMessage = nil
        self.isLookingUp = true
        self.lookupIP = ip

        if recordInHistory {
            self.history.recordLookup(ip)
        }

        logger.info("Starting lookup for \(ip)")

        let results = await service.lookupIP(ip)

        self.sourceResults = results.sorted { $0.sourceName < $1.sourceName }
        self.aggregatedResult = ResultAggregator.aggregate(self.sourceResults)

        let successCount = results.filter(\.isSuccess).count
        logger.info("Lookup complete: \(successCount)/\(results.count) sources returned data")

        self.isLookingUp = false
    }

    private func isValidIP(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        if parts.count == 4 {
            return parts.allSatisfy { part in
                guard let num = Int(part) else { return false }
                return num >= 0 && num <= 255
            }
        }

        // Basic IPv6 validation: contains colons and hex characters
        if ip.contains(":") {
            let cleaned = ip.replacingOccurrences(of: ":", with: "")
            return cleaned.allSatisfy(\.isHexDigit)
        }

        return false
    }
}
