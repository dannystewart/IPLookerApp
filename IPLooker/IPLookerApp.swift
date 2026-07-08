import PolyKit
import SwiftUI

#if os(macOS)
    import AppKit

    final class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationShouldOpenUntitledFile(_: NSApplication) -> Bool {
            false
        }

        func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
            false
        }
    }

#elseif os(iOS)
    import UIKit
#endif

#if os(macOS)
    private struct CopyPublicIPCommandAction {
        let isEnabled: Bool
        let perform: () -> Void
    }

    private struct CopyPublicIPCommandActionKey: FocusedValueKey {
        typealias Value = CopyPublicIPCommandAction
    }

    private struct WindowFloatingState {
        let get: () -> Bool
        let set: (Bool) -> Void

        var isFloating: Bool {
            self.get()
        }
    }

    private struct WindowFloatingStateKey: FocusedValueKey {
        typealias Value = WindowFloatingState
    }

    fileprivate extension FocusedValues {
        var copyPublicIPCommandAction: CopyPublicIPCommandAction? {
            get { self[CopyPublicIPCommandActionKey.self] }
            set { self[CopyPublicIPCommandActionKey.self] = newValue }
        }

        var windowFloatingState: WindowFloatingState? {
            get { self[WindowFloatingStateKey.self] }
            set { self[WindowFloatingStateKey.self] = newValue }
        }
    }

    private struct PublicIPCommands: Commands {
        @FocusedValue(\.copyPublicIPCommandAction) private var copyPublicIPCommandAction

        var body: some Commands {
            CommandGroup(after: .pasteboard) {
                Divider()

                Button {
                    self.copyPublicIPCommandAction?.perform()
                } label: {
                    Label("Copy Public IP", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
                .disabled(!(self.copyPublicIPCommandAction?.isEnabled ?? false))
            }
        }
    }

    private struct WindowCommands: Commands {
        @Environment(\.openWindow) private var openWindow
        @FocusedValue(\.windowFloatingState) private var windowFloatingState

        var body: some Commands {
            CommandGroup(replacing: .newItem) {
                Button {
                    self.openWindow(id: "main")
                } label: {
                    Label("New Window", systemImage: "macwindow.badge.plus")
                }
                .keyboardShortcut("n")
            }

            CommandGroup(after: .windowArrangement) {
                Toggle(
                    isOn: Binding(
                        get: { self.windowFloatingState?.isFloating ?? false },
                        set: { self.windowFloatingState?.set($0) },
                    ),
                ) {
                    Label("Always on Top", systemImage: "pin.circle")
                }
                .keyboardShortcut("t", modifiers: [.control, .command])
                .disabled(self.windowFloatingState == nil)
            }
        }
    }

    private enum WindowMetrics {
        static let minimumSize: CGSize = .init(width: 440, height: 400)
        static let defaultSize: CGSize = .init(width: 550, height: 550)
    }

    private struct WindowConfigurationModifier: ViewModifier {
        @State private var isAlwaysOnTop = false

        func body(content: Content) -> some View {
            content
                .background(WindowAccessor(isAlwaysOnTop: self.$isAlwaysOnTop))
                .focusedSceneValue(
                    \.windowFloatingState,
                    .init(
                        get: { self.isAlwaysOnTop },
                        set: { self.isAlwaysOnTop = $0 },
                    ),
                )
        }
    }

    private struct WindowAccessor: NSViewRepresentable {
        @Binding var isAlwaysOnTop: Bool

        func makeNSView(context _: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                self.updateWindow(from: view)
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context _: Context) {
            DispatchQueue.main.async {
                self.updateWindow(from: nsView)
            }
        }

        private func updateWindow(from view: NSView) {
            guard let window = view.window else { return }
            window.minSize = WindowMetrics.minimumSize
            window.level = self.isAlwaysOnTop ? .floating : .normal
            window.isRestorable = false
            window.identifier = nil
            window.restorationClass = nil
            window.tabbingMode = .disallowed
        }
    }
#endif // os(macOS)

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

    @State private var viewModel: LookupViewModel
    @State private var showCopiedConfirmation = false
    @State private var copyConfirmationTask: Task<Void, Never>? = nil
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

    #if os(macOS)
        @ToolbarContentBuilder
        private var browserToolbar: some ToolbarContent {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    Task { await self.viewModel.goBack() }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!self.viewModel.canGoBack || self.viewModel.isLookingUp)
                .help("Back")

                Button {
                    Task { await self.viewModel.goForward() }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!self.viewModel.canGoForward || self.viewModel.isLookingUp)
                .help("Forward")
            }

            ToolbarItemGroup(placement: .principal) {
                TextField("Enter IP address", text: self.$viewModel.ipInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .disabled(self.viewModel.isLookingUp)
                    .onSubmit {
                        Task { await self.viewModel.performLookup() }
                    }

                Button {
                    Task { await self.viewModel.refreshLookup() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(self.viewModel.lookupIP == nil || self.viewModel.isLookingUp)
                .help("Refresh")
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if self.viewModel.historyEntries.isEmpty {
                        Text("No History")
                    } else {
                        ForEach(self.viewModel.historyEntries.reversed()) { entry in
                            Button {
                                Task { await self.viewModel.selectHistoryEntry(entry) }
                            } label: {
                                Label(entry.ip, systemImage: entry.ip == self.viewModel.lookupIP ? "checkmark" : "network")
                            }
                        }
                    }

                    Divider()

                    Button("Clear History", role: .destructive) {
                        self.viewModel.clearHistory()
                    }
                    .disabled(!self.viewModel.hasHistory)
                } label: {
                    Image(systemName: "clock")
                }
                .menuStyle(.button)
                .disabled(self.viewModel.isLookingUp)
                .help("History")
            }
        }
    #endif // os(macOS)

    init(history: LookupHistoryStore = .init()) {
        self._viewModel = State(initialValue: LookupViewModel(history: history))
    }

    var body: some View {
        VStack(spacing: 0) {
            self.headerArea
            Divider()
            self.resultsArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if os(macOS)
            .frame(
                minWidth: WindowMetrics.minimumSize.width,
                idealWidth: WindowMetrics.defaultSize.width,
                minHeight: WindowMetrics.minimumSize.height,
                idealHeight: 400,
            )
        #endif // os(macOS)
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
        #endif // os(iOS)
        #if os(macOS)
            .toolbar {
            self.browserToolbar
        }
        .focusedSceneValue(
            \.copyPublicIPCommandAction,
            .init(
                isEnabled: self.viewModel.publicIP != nil,
                perform: self.copyCurrentPublicIP,
            ),
        )
        #endif // os(macOS)
        .onDisappear {
            self.copyConfirmationTask?.cancel()
            self.copyConfirmationTask = nil
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            #if os(iOS)
                self.lookupRow
            #endif
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
    #endif // os(iOS)

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
        .frame(height: 10)
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
                        self.copyCurrentPublicIP()
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
        #endif // os(iOS)
    }

    private func dismissKeyboardIfNeeded() {
        #if os(iOS)
            self.isIPFieldFocused = false
        #endif
    }

    private func copyCurrentPublicIP() {
        guard let publicIP = self.viewModel.publicIP else { return }
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(publicIP, forType: .string)
        #elseif os(iOS)
            UIPasteboard.general.string = publicIP
        #endif
        logger.info("Copied current public IP \(publicIP) to clipboard")
        self.showCopiedConfirmation = true
        self.copyConfirmationTask?.cancel()
        self.copyConfirmationTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self.showCopiedConfirmation = false
            self.copyConfirmationTask = nil
        }
    }
}

// MARK: - IPLookerApp

@main
struct IPLookerApp: App {
    @State private var lookupHistory: LookupHistoryStore = .init()

    var body: some Scene {
        #if os(macOS)
            WindowGroup(id: "main") {
                ContentView(history: self.lookupHistory)
                    .modifier(WindowConfigurationModifier())
            }
            .defaultSize(width: WindowMetrics.defaultSize.width, height: WindowMetrics.defaultSize.height)
            .windowToolbarStyle(.unified(showsTitle: false))
            .windowToolbarLabelStyle(fixed: .iconOnly)
            .commands {
                PolyAbout.Commands(info: .init(), currentAnnouncement: nil)
                PublicIPCommands()
                WindowCommands()
            }

            Settings {
                SettingsView()
            }
        #else
            WindowGroup {
                NavigationStack {
                    ContentView(history: self.lookupHistory)
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
