import Foundation

enum IPAPIIsSource: LookupSource {
    static let sourceName = "ipapi.is"
    static let apiURL = "https://api.ipapi.is?ip={ip}"
    static let apiKeyParam: String? = "key"

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var result = IPLookupResult(ip: ip, source: sourceName)

        if let location = json["location"] as? [String: Any] {
            result.country = location["country"] as? String
            result.region = location["state"] as? String
            result.city = location["city"] as? String
        }

        if let company = json["company"] as? [String: Any] {
            result.org = company["name"] as? String
        }

        if let asn = json["asn"] as? [String: Any] {
            if let asnNum = asn["asn"] {
                let asnStr = "\(asnNum)"
                result.asn = asnStr.hasPrefix("AS") ? asnStr : "AS\(asnStr)"
            }
            result.asnName = asn["org"] as? String ?? asn["name"] as? String

            if result.org == nil {
                result.org = asn["org"] as? String
            }
            if result.isp == nil {
                result.isp = asn["domain"] as? String
            }
            result.ipRange = asn["route"] as? String
        }

        if let datacenter = json["datacenter"] as? [String: Any] {
            result.isp = datacenter["datacenter"] as? String
        }

        result.isVPN = json["is_vpn"] as? Bool
        result.isProxy = json["is_proxy"] as? Bool
        result.isTor = json["is_tor"] as? Bool
        result.isDatacenter = json["is_datacenter"] as? Bool

        if
            let vpn = json["vpn"] as? [String: Any],
            vpn["is_vpn"] as? Bool == true,
            let service = vpn["service"] as? String
        {
            result.vpnService = service
        }

        return result
    }
}
