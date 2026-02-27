import Foundation

enum IPDataSource: LookupSource {
    static let sourceName = "ipdata.co"
    static let apiURL = "https://api.ipdata.co/{ip}"
    static let apiKeyParam: String? = "api-key"

    static func validateResponse(_ json: [String: Any]) -> String? {
        if let error = json["error"] as? [String: Any] {
            return error["message"] as? String ?? "Unknown error"
        }
        return nil
    }

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var result = IPLookupResult(
            ip: ip,
            source: sourceName,
            country: json["country_name"] as? String,
            region: json["region"] as? String,
            city: json["city"] as? String,
        )

        if let asnData = json["asn"] as? [String: Any] {
            result.isp = asnData["domain"] as? String
            result.org = asnData["name"] as? String
            if let asnNum = asnData["asn"] {
                let asnStr = "\(asnNum)"
                result.asn = asnStr.hasPrefix("AS") ? asnStr : "AS\(asnStr)"
            }
            result.asnName = asnData["name"] as? String
            result.ipRange = asnData["route"] as? String
        }

        if let threat = json["threat"] as? [String: Any] {
            result.isTor = threat["is_tor"] as? Bool
            result.isProxy = threat["is_proxy"] as? Bool
            result.isDatacenter = threat["is_datacenter"] as? Bool
            result.isAnonymous = threat["is_anonymous"] as? Bool
        }

        return result
    }
}
