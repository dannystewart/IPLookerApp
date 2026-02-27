import Foundation

enum IPAPISource: LookupSource {
    static let sourceName = "ip-api.com"
    static let apiURL = "http://ip-api.com/json/{ip}"
    static let requiresKey = false

    static func validateResponse(_ json: [String: Any]) -> String? {
        if let status = json["status"] as? String, status != "success" {
            return json["message"] as? String ?? "Lookup failed"
        }
        return nil
    }

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var result = IPLookupResult(
            ip: ip,
            source: sourceName,
            country: json["country"] as? String,
            region: json["regionName"] as? String,
            city: json["city"] as? String,
            isp: json["isp"] as? String,
            org: json["org"] as? String,
        )

        if let asInfo = json["as"] as? String {
            if let spaceIndex = asInfo.firstIndex(of: " ") {
                result.asn = String(asInfo[..<spaceIndex])
                result.asnName = String(asInfo[asInfo.index(after: spaceIndex)...])
            } else {
                result.asn = asInfo
            }
        }

        return result
    }
}
