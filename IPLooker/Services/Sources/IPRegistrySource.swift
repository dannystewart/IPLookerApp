import Foundation

enum IPRegistrySource: LookupSource {
    static let sourceName = "ipregistry.co"
    static let apiURL = "https://api.ipregistry.co/{ip}"
    static let requiresUserKey = true
    static let apiKeyParam: String? = "key"

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var data = json
        if let results = data["results"] as? [[String: Any]], let first = results.first {
            data = first
        }

        var result = IPLookupResult(ip: ip, source: sourceName)

        if let location = data["location"] as? [String: Any] {
            if let country = location["country"] as? [String: Any] {
                result.country = country["name"] as? String
            }
            if let region = location["region"] as? [String: Any] {
                result.region = region["name"] as? String
            }
            result.city = location["city"] as? String
        }

        if let connection = data["connection"] as? [String: Any] {
            result.isp = connection["domain"] as? String
            result.org = connection["organization"] as? String

            if let asnNum = connection["asn"] {
                let asnStr = "\(asnNum)"
                result.asn = asnStr.hasPrefix("AS") ? asnStr : "AS\(asnStr)"
            }
            result.asnName = connection["organization"] as? String
            result.ipRange = connection["route"] as? String
        } else if let company = data["company"] as? [String: Any] {
            result.org = company["name"] as? String
        }

        if let security = data["security"] as? [String: Any] {
            result.isVPN = security["is_vpn"] as? Bool
            result.isProxy = security["is_proxy"] as? Bool
            result.isTor = security["is_tor"] as? Bool
            result.isDatacenter = security["is_cloud_provider"] as? Bool
            result.isAnonymous = security["is_anonymous"] as? Bool
        }

        return result
    }
}
