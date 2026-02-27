import Foundation
import PolyKit

// MARK: - LookupSource

protocol LookupSource: Sendable {
    static var sourceName: String { get }
    static var apiURL: String { get }
    static var requiresKey: Bool { get }
    static var requiresUserKey: Bool { get }
    static var apiKeyParam: String? { get }
    static var timeout: TimeInterval { get }

    static func lookup(ip: String) async -> SourceResult
    static func buildURL(ip: String, key: String) -> URL?
    static func validateResponse(_ json: [String: Any]) -> String?
    static func parseResponse(_ json: [String: Any], ip: String) -> IPLookupResult
}

extension LookupSource {
    static var requiresKey: Bool { true }
    static var requiresUserKey: Bool { false }
    static var apiKeyParam: String? { nil }
    static var timeout: TimeInterval { 5 }

    static func lookup(ip: String) async -> SourceResult {
        let key: String
        if self.requiresKey {
            key = APIKeyManager.key(for: sourceName, requiresUserKey: self.requiresUserKey)
            if key.isEmpty {
                let reason = self.requiresUserKey ? "No user key" : "No key"
                return SourceResult(id: sourceName, sourceName: sourceName, status: .skipped(reason: reason))
            }
        } else {
            key = ""
        }

        let url = self.buildURL(ip: ip, key: key)
        guard let url else {
            return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Bad URL"))
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: self.timeout))

            guard let httpResponse = response as? HTTPURLResponse else {
                return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Invalid response"))
            }

            if httpResponse.statusCode == 429 {
                return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Rate limited"))
            }

            guard httpResponse.statusCode == 200 else {
                return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "HTTP \(httpResponse.statusCode)"))
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Invalid JSON"))
            }

            if let validationError = validateResponse(json) {
                return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: validationError))
            }

            let result = self.parseResponse(json, ip: ip)
            logger.debug("[\(sourceName)] Lookup succeeded for \(ip)")
            return SourceResult(id: sourceName, sourceName: sourceName, status: .success(result))
        } catch is CancellationError {
            return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Cancelled"))
        } catch let error as URLError where error.code == .timedOut {
            return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Timeout"))
        } catch {
            logger.error("[\(sourceName)] Request failed: \(error.localizedDescription)")
            return SourceResult(id: sourceName, sourceName: sourceName, status: .failed(reason: "Request failed"))
        }
    }

    static func buildURL(ip: String, key: String) -> URL? {
        let urlString = apiURL.replacingOccurrences(of: "{ip}", with: ip)
        guard var components = URLComponents(string: urlString) else { return nil }

        var queryItems = components.queryItems ?? []
        if let param = apiKeyParam, !key.isEmpty {
            queryItems.append(URLQueryItem(name: param, value: key))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }

    static func validateResponse(_: [String: Any]) -> String? {
        nil
    }

    static func parseResponse(_: [String: Any], ip: String) -> IPLookupResult {
        IPLookupResult(ip: ip, source: sourceName)
    }
}
