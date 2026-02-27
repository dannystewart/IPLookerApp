import Foundation
import PolyKit

actor IPLookupService {
    static let shared: IPLookupService = .init()

    private let allSources: [any LookupSource.Type] = [
        IPAPISource.self,
        IPAPICoSource.self,
        IPAPIIsSource.self,
        IPDataSource.self,
        IPGeolocationSource.self,
        IPInfoSource.self,
        IPLocateSource.self,
        IPRegistrySource.self,
    ]

    func fetchPublicIP() async -> String? {
        logger.info("Fetching public IP address")
        do {
            let url = URL(string: "https://api.ipify.org")!
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                logger.error("Public IP fetch returned non-200 status")
                return nil
            }
            let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("Public IP: \(ip ?? "nil")")
            return ip
        } catch {
            logger.error("Failed to fetch public IP: \(error.localizedDescription)")
            return nil
        }
    }

    func lookupIP(_ ip: String) async -> [SourceResult] {
        logger.info("Looking up IP: \(ip)")

        return await withTaskGroup(of: SourceResult.self, returning: [SourceResult].self) { group in
            for source in self.allSources {
                group.addTask {
                    await source.lookup(ip: ip)
                }
            }

            var results = [SourceResult]()
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}
