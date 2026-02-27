import Foundation

enum IPLocateSource: LookupSource {
    static let sourceName = "iplocate.io"
    static let apiURL = "https://iplocate.io/api/lookup/{ip}"
    static let apiKeyParam: String? = "apiKey"

    static func validateResponse(_ json: [String: Any]) -> String? {
        if let error = json["error"] as? String {
            return error
        }
        return nil
    }

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var result = IPLookupResult(
            ip: ip,
            source: sourceName,
            country: json["country"] as? String,
            region: json["subdivision"] as? String,
            city: json["city"] as? String,
        )

        if let company = json["company"] as? [String: Any] {
            result.org = company["name"] as? String
        }

        if let asn = json["asn"] as? [String: Any] {
            result.isp = asn["name"] as? String ?? asn["domain"] as? String
            if result.org == nil {
                result.org = asn["name"] as? String
            }

            if let asnNum = asn["asn"] {
                let asnStr = "\(asnNum)"
                result.asn = asnStr.hasPrefix("AS") ? asnStr : "AS\(asnStr)"
            }
            result.asnName = asn["name"] as? String
            result.ipRange = asn["route"] as? String
        }

        return result
    }
}
