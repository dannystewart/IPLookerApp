import Foundation

// MARK: - IPLookupResult

struct IPLookupResult {
    let ip: String
    let source: String

    var country: String?
    var region: String?
    var city: String?
    var isp: String?
    var org: String?

    var asn: String?
    var asnName: String?
    var ipRange: String?

    var isVPN: Bool?
    var vpnService: String?
    var isProxy: Bool?
    var isTor: Bool?
    var isDatacenter: Bool?
    var isAnonymous: Bool?
}

// MARK: - SourceStatus

enum SourceStatus {
    case success(IPLookupResult)
    case failed(reason: String)
    case skipped(reason: String)
}

// MARK: - SourceResult

struct SourceResult: Identifiable {
    let id: String
    let sourceName: String
    let status: SourceStatus

    var result: IPLookupResult? {
        if case let .success(result) = status { return result }
        return nil
    }

    var isSuccess: Bool {
        if case .success = self.status { return true }
        return false
    }

    var statusDescription: String {
        switch self.status {
        case .success:
            "OK"
        case let .failed(reason):
            reason
        case let .skipped(reason):
            reason
        }
    }
}
