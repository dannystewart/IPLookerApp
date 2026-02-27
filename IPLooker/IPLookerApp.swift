import PolyKit
import SwiftUI

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

// MARK: - ContentView

struct ContentView: View {
    // MARK: - ClearableTextField

    private struct ClearableTextField: View {
        @Binding var text: String

        let titleKey: LocalizedStringKey
        let isClearButtonVisible: Bool
        let isClearButtonEnabled: Bool
        let isFocused: FocusState<Bool>.Binding?
        let onSubmit: () -> Void
        let onClear: () -> Void

        init(
            _ titleKey: LocalizedStringKey,
            text: Binding<String>,
            isClearButtonVisible: Bool,
            isClearButtonEnabled: Bool = true,
            isFocused: FocusState<Bool>.Binding? = nil,
            onSubmit: @escaping () -> Void,
            onClear: @escaping () -> Void,
        ) {
            self.titleKey = titleKey
            self._text = text
            self.isClearButtonVisible = isClearButtonVisible
            self.isClearButtonEnabled = isClearButtonEnabled
            self.isFocused = isFocused
            self.onSubmit = onSubmit
            self.onClear = onClear
        }

        var body: some View {
            self.textField
                .textFieldStyle(.roundedBorder)
                .onSubmit(self.onSubmit)
                .padding(.trailing, self.isClearButtonVisible ? 26 : 0)
                .overlay(alignment: .trailing) {
                    if self.isClearButtonVisible {
                        Button {
                            self.onClear()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(!self.isClearButtonEnabled)
                        .padding(.trailing, 6)
                        .accessibilityLabel("Clear")
                        #if os(macOS)
                            .help("Clear")
                        #endif
                    }
                }
        }

        @ViewBuilder
        private var textField: some View {
            #if os(iOS)
                if let isFocused = self.isFocused {
                    TextField(self.titleKey, text: self.$text)
                        .focused(isFocused)
                } else {
                    TextField(self.titleKey, text: self.$text)
                }
            #else
                TextField(self.titleKey, text: self.$text)
            #endif
        }
    }

    @State private var viewModel: LookupViewModel = .init()
    @State private var showCopiedConfirmation = false
    @State private var isShowingSettings = false
    #if os(iOS)
        @FocusState private var isIPFieldFocused: Bool
    #endif

    private var ipFieldFocusBinding: FocusState<Bool>.Binding? {
        #if os(iOS)
            self.$isIPFieldFocused
        #else
            nil
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            self.headerArea
            Divider()
            self.resultsArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if os(macOS)
            .frame(minWidth: 500, idealWidth: 560, minHeight: 400, idealHeight: 600)
        #endif
            .task {
                async let publicIP: Void = self.viewModel.fetchPublicIP()
                #if os(macOS)
                    async let clipboard: Void = self.viewModel.checkClipboardForIP()
                    await clipboard
                #endif
                await publicIP
            }
        #if os(iOS)
            .navigationTitle("IPLooker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.isShowingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: self.$isShowingSettings) {
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    self.isShowingSettings = false
                                }
                            }
                        }
                }
            }
        #endif
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            self.lookupRow
            self.publicIPRow
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lookupRow: some View {
        #if os(iOS)
            ViewThatFits(in: .horizontal) {
                self.lookupRowHorizontal
                self.lookupRowVertical
            }
        #else
            self.lookupRowHorizontal
        #endif
    }

    #if os(iOS)
        private var lookupRowVertical: some View {
            VStack(spacing: 10) {
                ClearableTextField(
                    "Enter IP address",
                    text: self.$viewModel.ipInput,
                    isClearButtonVisible: !self.viewModel.ipInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.viewModel.hasResults,
                    isClearButtonEnabled: !self.viewModel.isLookingUp,
                    isFocused: self.ipFieldFocusBinding,
                    onSubmit: {
                        self.dismissKeyboardIfNeeded()
                        Task { await self.viewModel.performLookup() }
                    },
                    onClear: { self.viewModel.clear() },
                )
                .frame(maxWidth: .infinity)

                Spacer()

                Button("Look Up") {
                    self.dismissKeyboardIfNeeded()
                    Task { await self.viewModel.performLookup() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.viewModel.ipInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.viewModel.isLookingUp)
            }
            .frame(maxWidth: .infinity)
        }
    #endif

    private var lookupRowHorizontal: some View {
        HStack(spacing: 8) {
            ClearableTextField(
                "Enter IP address",
                text: self.$viewModel.ipInput,
                isClearButtonVisible: !self.viewModel.ipInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.viewModel.hasResults,
                isClearButtonEnabled: !self.viewModel.isLookingUp,
                isFocused: self.ipFieldFocusBinding,
                onSubmit: {
                    self.dismissKeyboardIfNeeded()
                    Task { await self.viewModel.performLookup() }
                },
                onClear: { self.viewModel.clear() },
            )
            .frame(maxWidth: .infinity)

            Button("Look Up") {
                self.dismissKeyboardIfNeeded()
                Task { await self.viewModel.performLookup() }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(self.viewModel.ipInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.viewModel.isLookingUp)
        }
        .frame(maxWidth: .infinity)
    }

    private var publicIPRow: some View {
        Group {
            HStack {
                self.publicIPLabel

                Spacer()

                if self.viewModel.publicIP != nil {
                    Button("Look Up My IP") {
                        Task { await self.viewModel.lookupMyIP() }
                    }
                    .controlSize(.small)
                }
            }
        }
        #if os(macOS)
        .frame(height: 20)
        #endif
    }

    private var publicIPLabel: some View {
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
                        #if os(macOS)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ip, forType: .string)
                        #elseif os(iOS)
                            UIPasteboard.general.string = ip
                        #endif
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
                    #if os(macOS)
                        .help("Copy to clipboard")
                    #endif
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                #endif
                .frame(maxWidth: .infinity)
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
        #if os(iOS)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                self.dismissKeyboardIfNeeded()
            },
        )
        #endif
    }

    private func dismissKeyboardIfNeeded() {
        #if os(iOS)
            self.isIPFieldFocused = false
        #endif
    }
}

// MARK: - IPLookerApp

@main
struct IPLookerApp: App {
    var body: some Scene {
        #if os(macOS)
            WindowGroup {
                ContentView()
            }
            .defaultSize(width: 550, height: 550)
            .commands {
                PolyAbout.Commands(info: .init(), currentAnnouncement: nil)
            }

            Settings {
                SettingsView()
            }
        #else
            WindowGroup {
                NavigationStack {
                    ContentView()
                }
                .polyAboutSupport(aboutInfo: .init())
            }
            .commands {
                PolyAbout.Commands(info: .init(), currentAnnouncement: nil)
            }
        #endif
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
