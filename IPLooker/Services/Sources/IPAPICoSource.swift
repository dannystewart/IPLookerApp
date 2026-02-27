import Foundation

enum IPAPICoSource: LookupSource {
    static let sourceName = "ipapi.co"
    static let apiURL = "https://ipapi.co/{ip}/json/"
    static let requiresKey = false

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        IPLookupResult(
            ip: ip,
            source: self.sourceName,
            country: json["country_name"] as? String,
            region: json["region"] as? String,
            city: json["city"] as? String,
            org: json["org"] as? String,
        )
    }
}
