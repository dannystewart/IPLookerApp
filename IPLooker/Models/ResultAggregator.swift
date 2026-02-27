import Foundation

// MARK: - AggregatedResult

struct AggregatedResult: Sendable {
    var city: String? = nil
    var region: String? = nil
    var country: String? = nil
    var isp: String? = nil
    var org: String? = nil
    var asn: String? = nil
    var asnName: String? = nil
    var ipRange: String? = nil

    var isVPN: Bool
    var vpnService: String? = nil
    var isProxy: Bool
    var isTor: Bool
    var isDatacenter: Bool
    var isAnonymous: Bool

    var sourceCount: Int
    var successCount: Int
    var locationAgreement: Int

    var locationString: String {
        [self.city, self.region, self.country].compactMap(\.self).joined(separator: ", ")
    }

    var hasSecurityFlags: Bool {
        self.isVPN || self.isProxy || self.isTor || self.isDatacenter || self.isAnonymous
    }

    var securityFlags: [String] {
        var flags = [String]()
        if self.isVPN {
            if let service = vpnService {
                flags.append("VPN (\(service))")
            } else {
                flags.append("VPN")
            }
        }
        if self.isProxy { flags.append("Proxy") }
        if self.isTor { flags.append("Tor Exit Node") }
        if self.isDatacenter { flags.append("Datacenter") }
        if self.isAnonymous, flags.isEmpty { flags.append("Anonymous") }
        return flags
    }
}

// MARK: - ResultAggregator

enum ResultAggregator {
    static func aggregate(_ sourceResults: [SourceResult]) -> AggregatedResult? {
        let results = sourceResults.compactMap(\.result)
        guard !results.isEmpty else { return nil }

        let city = self.mostCommon(results.compactMap(\.city))
        let region = self.mostCommon(results.compactMap(\.region))
        let country = self.mostCommon(results.compactMap(\.country))

        let locationAgreement: Int = if let city {
            results.count(where: { $0.city == city })
        } else {
            0
        }

        return AggregatedResult(
            city: city,
            region: region,
            country: country,
            isp: self.firstNonEmpty(results.compactMap(\.isp)),
            org: self.firstNonEmpty(results.compactMap(\.org)),
            asn: self.firstNonEmpty(results.compactMap(\.asn)),
            asnName: self.firstNonEmpty(results.compactMap(\.asnName)),
            ipRange: self.firstNonEmpty(results.compactMap(\.ipRange)),
            isVPN: results.contains { $0.isVPN == true },
            vpnService: results.compactMap(\.vpnService).first,
            isProxy: results.contains { $0.isProxy == true },
            isTor: results.contains { $0.isTor == true },
            isDatacenter: results.contains { $0.isDatacenter == true },
            isAnonymous: results.contains { $0.isAnonymous == true },
            sourceCount: sourceResults.count,
            successCount: results.count,
            locationAgreement: locationAgreement,
        )
    }

    private static func mostCommon(_ values: [String]) -> String? {
        let filtered = values.filter { !$0.isEmpty }
        guard !filtered.isEmpty else { return nil }

        var counts = [String: Int]()
        for value in filtered {
            counts[value, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private static func firstNonEmpty(_ values: [String]) -> String? {
        values.first { !$0.isEmpty && !$0.lowercased().hasPrefix("unknown") }
    }
}
