import Foundation

// MARK: - IPLookupResult

struct IPLookupResult {
    let ip: String
    let source: String

    var country: String? = nil
    var region: String? = nil
    var city: String? = nil
    var isp: String? = nil
    var org: String? = nil

    var asn: String? = nil
    var asnName: String? = nil
    var ipRange: String? = nil

    var isVPN: Bool? = nil
    var vpnService: String? = nil
    var isProxy: Bool? = nil
    var isTor: Bool? = nil
    var isDatacenter: Bool? = nil
    var isAnonymous: Bool? = nil
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
