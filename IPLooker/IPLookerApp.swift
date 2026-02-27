import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @State private var viewModel: LookupViewModel = .init()
    @State private var showCopiedConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            self.headerArea
            Divider()
            self.resultsArea
        }
        .frame(minWidth: 500, idealWidth: 560, minHeight: 400, idealHeight: 600)
        .task {
            async let clipboard: Void = self.viewModel.checkClipboardForIP()
            async let publicIP: Void = self.viewModel.fetchPublicIP()
            await clipboard
            await publicIP
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            self.lookupRow
            self.publicIPRow
        }
        .padding()
    }

    private var lookupRow: some View {
        HStack(spacing: 8) {
            TextField("Enter IP address", text: self.$viewModel.ipInput)
                .textFieldStyle(.roundedBorder)
                .fontDesign(.monospaced)
                .onSubmit {
                    Task { await self.viewModel.performLookup() }
                }

            if self.viewModel.hasResults {
                Button {
                    self.viewModel.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear results")
            }

            Button("Look Up") {
                Task { await self.viewModel.performLookup() }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(self.viewModel.ipInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.viewModel.isLookingUp)
        }
    }

    private var publicIPRow: some View {
        HStack {
            Label {
                if self.viewModel.isLoadingPublicIP {
                    Text("Detecting...")
                        .foregroundStyle(.secondary)
                } else if let ip = viewModel.publicIP {
                    HStack(spacing: 4) {
                        Text("Your Public IP:")
                            .fontWeight(.medium)
                            .padding(.trailing, 4)

                        Text(ip)
                            .textSelection(.enabled)
                            .fontDesign(.monospaced)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ip, forType: .string)
                            self.showCopiedConfirmation = true
                            Task {
                                try? await Task.sleep(for: .seconds(1))
                                self.showCopiedConfirmation = false
                            }
                        } label: {
                            Image(systemName: self.showCopiedConfirmation ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .help("Copy to clipboard")
                        .padding(.leading, 6)
                    }
                } else {
                    Text("Unavailable")
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "network")
            }
            .font(.headline)
            .fontWeight(.regular)

            Spacer()

            if self.viewModel.publicIP != nil {
                Button("Look Up My IP") {
                    Task { await self.viewModel.lookupMyIP() }
                }
                .controlSize(.small)
            }
        }
        .frame(height: 20)
    }

    // MARK: - Results

    private var resultsArea: some View {
        Group {
            if self.viewModel.isLookingUp {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Querying sources...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let aggregated = viewModel.aggregatedResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let ip = viewModel.lookupIP {
                            Text("Results for \(ip)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.bottom, 4)
                        }

                        AggregatedResultsView(result: aggregated)

                        SourceBreakdownView(sourceResults: self.viewModel.sourceResults)
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "globe.americas")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Enter an IP address to look up")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - IPLookerApp

@main
struct IPLookerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 550, height: 550)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
