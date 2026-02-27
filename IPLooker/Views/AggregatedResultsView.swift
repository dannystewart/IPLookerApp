import SwiftUI

// MARK: - AggregatedResultsView

struct AggregatedResultsView: View {
    let result: AggregatedResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            self.locationSection
            self.networkSection
            self.securitySection
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        ResultSection(title: "Location", icon: "mappin.and.ellipse") {
            if self.result.locationString.isEmpty {
                Text("Unknown Location")
                    .foregroundStyle(.secondary)
            } else {
                Text(self.result.locationString)
                    .font(.title3)
                    .fontWeight(.medium)
                    .textSelection(.enabled)

                if self.result.locationAgreement > 0 {
                    Text("\(self.result.locationAgreement) of \(self.result.successCount) sources agree")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Network

    private var networkSection: some View {
        ResultSection(title: "Network", icon: "antenna.radiowaves.left.and.right") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                if let isp = result.isp {
                    self.networkRow(label: "ISP", value: isp)
                }
                if let org = result.org, org != result.isp {
                    self.networkRow(label: "Organization", value: org)
                }
                if let asn = result.asn {
                    let asnDisplay = if let name = result.asnName { "\(asn) (\(name))" } else { asn }
                    self.networkRow(label: "ASN", value: asnDisplay)
                }
                if let ipRange = result.ipRange {
                    self.networkRow(label: "IP Range", value: ipRange)
                }
            }

            if self.result.isp == nil, self.result.org == nil, self.result.asn == nil {
                Text("No network information available")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        ResultSection(title: "Security", icon: "shield") {
            if self.result.hasSecurityFlags {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(self.result.securityFlags, id: \.self) { flag in
                        Label(flag, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                Label("No security flags detected", systemImage: "checkmark.shield")
                    .foregroundStyle(.green)
            }
        }
    }

    private func networkRow(label: String, value: String) -> some View {
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

// MARK: - ResultSection

struct ResultSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                self.content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(self.title, systemImage: self.icon)
                .font(.headline)
        }
    }
}
