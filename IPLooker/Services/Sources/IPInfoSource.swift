import Foundation

enum IPInfoSource: LookupSource {
    static let sourceName = "ipinfo.io"
    static let apiURL = "https://ipinfo.io/{ip}/json"
    static let apiKeyParam: String? = "token"

    static func validateResponse(_ json: [String: Any]) -> String? {
        if json["error"] != nil || json["message"] != nil {
            if let error = json["error"] as? [String: Any] {
                return error["message"] as? String ?? "Unknown error"
            }
            return json["message"] as? String
        }
        return nil
    }

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var result = IPLookupResult(
            ip: ip,
            source: sourceName,
            country: json["country"] as? String,
            region: json["region"] as? String,
            city: json["city"] as? String,
        )

        self.extractOrganizationInfo(json, result: &result)
        self.extractASNInfo(json, result: &result)
        self.extractSecurityInfo(json, result: &result)

        result.ipRange = json["cidr"] as? String

        return result
    }

    private static func extractOrganizationInfo(_ json: [String: Any], result: inout IPLookupResult) {
        if let org = json["org"] as? String {
            if let spaceIndex = org.firstIndex(of: " ") {
                let asnPart = String(org[..<spaceIndex])
                let orgName = String(org[org.index(after: spaceIndex)...])
                result.asn = asnPart
                result.asnName = orgName
                result.isp = orgName
                result.org = orgName
            } else {
                result.org = org
            }
        }

        if result.org == nil {
            if let company = json["company"] as? [String: Any] {
                result.org = company["name"] as? String
            } else if let company = json["company"] as? String {
                result.org = company
            }
        }
    }

    private static func extractASNInfo(_ json: [String: Any], result: inout IPLookupResult) {
        guard result.isp == nil else { return }

        if let asn = json["asn"] as? [String: Any] {
            result.isp = asn["name"] as? String ?? asn["domain"] as? String
            if result.asn == nil { result.asn = asn["asn"] as? String }
            if result.asnName == nil { result.asnName = asn["name"] as? String }
        } else if let asn = json["asn"] as? String, asn.contains(" ") {
            let parts = asn.split(separator: " ", maxSplits: 1)
            result.isp = String(parts[1])
            if result.asn == nil { result.asn = String(parts[0]) }
            if result.asnName == nil { result.asnName = String(parts[1]) }
        }
    }

    private static func extractSecurityInfo(_ json: [String: Any], result: inout IPLookupResult) {
        guard let privacy = json["privacy"] as? [String: Any] else { return }
        result.isVPN = privacy["vpn"] as? Bool
        result.isProxy = privacy["proxy"] as? Bool
        result.isTor = privacy["tor"] as? Bool
        result.isDatacenter = privacy["hosting"] as? Bool
        result.vpnService = privacy["service"] as? String
    }
}
