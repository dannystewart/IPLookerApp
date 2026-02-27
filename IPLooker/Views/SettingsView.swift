import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    private let services: [ServiceInfo] = [
        ServiceInfo(id: "ipapi.is", name: "ipapi.is", hasEmbeddedKey: true),
        ServiceInfo(id: "ipdata.co", name: "ipdata.co", hasEmbeddedKey: true),
        ServiceInfo(id: "ipgeolocation.io", name: "ipgeolocation.io", hasEmbeddedKey: true),
        ServiceInfo(id: "ipinfo.io", name: "ipinfo.io", hasEmbeddedKey: true),
        ServiceInfo(id: "iplocate.io", name: "iplocate.io", hasEmbeddedKey: true),
        ServiceInfo(id: "ipregistry.co", name: "ipregistry.co", hasEmbeddedKey: false),
    ]

    var body: some View {
        Form {
            Section {
                Text("Two sources (ip-api.com, ipapi.co) are free and require no API key. The services below use embedded keys by default. You can provide your own keys to ensure higher rate limits.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("API Keys") {
                ForEach(self.services) { service in
                    APIKeyRow(service: service)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 420)
    }
}

// MARK: - ServiceInfo

private struct ServiceInfo: Identifiable {
    let id: String
    let name: String
    let hasEmbeddedKey: Bool
}

// MARK: - APIKeyRow

private struct APIKeyRow: View {
    @State private var key: String = ""
    @State private var isEditing = false

    let service: ServiceInfo

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(self.service.name)
                    .fontWeight(.medium)
                if !self.isEditing {
                    self.statusLabel
                }
            }

            Spacer()

            if self.isEditing {
                TextField("API Key", text: self.$key)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 250)

                Button("Save") {
                    APIKeyManager.setUserKey(self.key, for: self.service.id)
                    self.isEditing = false
                }
                .controlSize(.small)

                Button("Cancel") {
                    self.key = APIKeyManager.userKey(for: self.service.id) ?? ""
                    self.isEditing = false
                }
                .controlSize(.small)
            } else {
                if APIKeyManager.userKey(for: self.service.id)?.isEmpty == false {
                    Button("Clear") {
                        APIKeyManager.deleteUserKey(for: self.service.id)
                        self.key = ""
                    }
                    .controlSize(.small)
                }

                Button("Edit") {
                    self.key = APIKeyManager.userKey(for: self.service.id) ?? ""
                    self.isEditing = true
                }
                .controlSize(.small)
            }
        }
        .onAppear {
            self.key = APIKeyManager.userKey(for: self.service.id) ?? ""
        }
    }

    private var statusLabel: some View {
        Group {
            if let userKey = APIKeyManager.userKey(for: service.id), !userKey.isEmpty {
                Label("Using your key", systemImage: "key.fill")
                    .foregroundStyle(.green)
            } else if self.service.hasEmbeddedKey {
                Label("Using built-in key", systemImage: "key")
                    .foregroundStyle(.secondary)
            } else {
                Label("No key configured", systemImage: "key")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption)
    }
}
