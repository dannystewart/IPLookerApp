import Foundation
import PolyKit
import SwiftUI

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

    var hasResults: Bool {
        self.aggregatedResult != nil
    }

    func fetchPublicIP() async {
        guard !self.isLoadingPublicIP else { return }
        self.isLoadingPublicIP = true
        defer { isLoadingPublicIP = false }

        self.publicIP = await self.service.fetchPublicIP()
    }

    func performLookup() async {
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

        logger.info("Starting lookup for \(ip)")

        let results = await service.lookupIP(ip)

        self.sourceResults = results.sorted { $0.sourceName < $1.sourceName }
        self.aggregatedResult = ResultAggregator.aggregate(self.sourceResults)

        let successCount = results.filter(\.isSuccess).count
        logger.info("Lookup complete: \(successCount)/\(results.count) sources returned data")

        self.isLookingUp = false
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
