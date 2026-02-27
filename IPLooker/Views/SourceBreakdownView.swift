import SwiftUI

// MARK: - SourceBreakdownView

struct SourceBreakdownView: View {
    @State private var isExpanded = false

    let sourceResults: [SourceResult]

    private var successCount: Int {
        self.sourceResults.filter(\.isSuccess).count
    }

    var body: some View {
        DisclosureGroup(isExpanded: self.$isExpanded) {
            VStack(spacing: 1) {
                ForEach(self.sourceResults) { source in
                    SourceRowView(source: source)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } label: {
            Label(
                "\(self.successCount) of \(self.sourceResults.count) sources returned data",
                systemImage: "list.bullet",
            )
            .font(.headline)
        }
    }
}

// MARK: - SourceRowView

private struct SourceRowView: View {
    @State private var isDetailExpanded = false

    let source: SourceResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                self.statusIcon
                Text(self.source.sourceName)
                    .fontWeight(.medium)
                Spacer()
                self.statusText
                if self.source.isSuccess {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(self.isDetailExpanded ? 90 : 0))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                if self.source.isSuccess {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isDetailExpanded.toggle()
                    }
                }
            }

            if self.isDetailExpanded, let result = source.result {
                SourceDetailView(result: result)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(self.source.isSuccess ? Color.primary.opacity(0.03) : Color.clear)
    }

    private var statusIcon: some View {
        Group {
            switch self.source.status {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)

            case .skipped:
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.gray)
            }
        }
        .font(.callout)
    }

    private var statusText: some View {
        Group {
            switch self.source.status {
            case let .success(result):
                Text(self.locationSummary(result))
                    .foregroundStyle(.secondary)

            case let .failed(reason), let .skipped(reason):
                Text(reason)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
    }

    private func locationSummary(_ result: IPLookupResult) -> String {
        [result.city, result.region, result.country]
            .compactMap(\.self)
            .joined(separator: ", ")
    }
}

// MARK: - SourceDetailView

private struct SourceDetailView: View {
    let result: IPLookupResult

    private var securitySummary: String? {
        var flags = [String]()
        if self.result.isVPN == true {
            if let service = result.vpnService {
                flags.append("VPN (\(service))")
            } else {
                flags.append("VPN")
            }
        }
        if self.result.isProxy == true { flags.append("Proxy") }
        if self.result.isTor == true { flags.append("Tor") }
        if self.result.isDatacenter == true { flags.append("Datacenter") }
        if self.result.isAnonymous == true { flags.append("Anonymous") }
        return flags.isEmpty ? nil : flags.joined(separator: ", ")
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
            if let country = result.country {
                self.detailRow("Country", country)
            }
            if let region = result.region {
                self.detailRow("Region", region)
            }
            if let city = result.city {
                self.detailRow("City", city)
            }
            if let isp = result.isp {
                self.detailRow("ISP", isp)
            }
            if let org = result.org {
                self.detailRow("Organization", org)
            }
            if let asn = result.asn {
                let display = if let name = result.asnName { "\(asn) (\(name))" } else { asn }
                self.detailRow("ASN", display)
            }
            if let ipRange = result.ipRange {
                self.detailRow("IP Range", ipRange)
            }
            if let securityInfo = securitySummary {
                self.detailRow("Security", securityInfo)
            }
        }
        .font(.callout)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .textSelection(.enabled)
                .gridColumnAlignment(.leading)
        }
    }
}
