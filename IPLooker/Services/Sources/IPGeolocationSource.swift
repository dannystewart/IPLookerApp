import Foundation

enum IPGeolocationSource: LookupSource {
    static let sourceName = "ipgeolocation.io"
    static let apiURL = "https://api.ipgeolocation.io/v2/ipgeo"
    static let apiKeyParam: String? = "apiKey"

    static func buildURL(ip: String, key: String) -> URL? {
        guard var components = URLComponents(string: apiURL) else { return nil }

        var queryItems = [URLQueryItem(name: "ip", value: ip)]
        if !key.isEmpty {
            queryItems.append(URLQueryItem(name: "apiKey", value: key))
        }
        components.queryItems = queryItems
        return components.url
    }

    static func validateResponse(_ json: [String: Any]) -> String? {
        if let status = json["status"] as? Int, status != 200 {
            return json["message"] as? String ?? "Status \(status)"
        }
        return nil
    }

    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult {
        var result = IPLookupResult(ip: ip, source: sourceName)

        if let location = json["location"] as? [String: Any] {
            result.country = location["country_name"] as? String
            result.region = location["state_prov"] as? String
            result.city = location["city"] as? String
        }

        return result
    }
}
