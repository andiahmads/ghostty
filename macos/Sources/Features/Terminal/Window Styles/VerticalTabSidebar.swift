import AppKit
import Combine
import SwiftUI

/// A custom tab list that presents the existing native macOS tab group vertically.
struct VerticalTabSidebar: View {
    weak var windowController: TerminalController?

    @StateObject private var model = VerticalTabSidebarModel()
    @AppStorage("ghostty.verticalTabSidebarWidth") private var sidebarWidth = 250.0
    @State private var resizeStartWidth: Double?
    @State private var searchText = ""

    private let minimumWidth = 180.0
    private let maximumWidth = 420.0

    private var filteredTabs: [VerticalTabSidebarModel.Item] {
        guard !searchText.isEmpty else { return model.items }
        return model.items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                header

                Divider()

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredTabs) { item in
                            VerticalTabRow(
                                item: item,
                                onSelect: { model.select(item) },
                                onClose: { model.close(item) },
                                onRename: { model.rename(item) }
                            )
                        }
                    }
                    .padding(8)
                }
            }
            .frame(width: sidebarWidth)
            .background(Color(nsColor: .windowBackgroundColor))

            resizeHandle
        }
        .onAppear {
            model.connect(to: windowController?.window)
        }
        .onDisappear {
            model.disconnect()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search tabs...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            Button(action: model.createTab) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(.plain)
            .help("New Tab")
        }
        .padding(8)
    }

    private var resizeHandle: some View {
        ZStack {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)

            Rectangle()
                .fill(Color.clear)
                .frame(width: 7)
                .contentShape(Rectangle())
        }
        .frame(width: 7)
        .onHover { hovering in
            if hovering {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if resizeStartWidth == nil {
                        resizeStartWidth = sidebarWidth
                    }

                    let initialWidth = resizeStartWidth ?? sidebarWidth
                    sidebarWidth = min(maximumWidth, max(minimumWidth, initialWidth + value.translation.width))
                }
                .onEnded { _ in
                    resizeStartWidth = nil
                }
        )
    }
}

private struct VerticalTabRow: View {
    let item: VerticalTabSidebarModel.Item
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(item.isSelected ? Color.primary : Color.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Ghostty" : item.title)
                    .font(.system(size: 12, weight: item.isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 4)

            if isHovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.plain)
                .help("Close Tab")
            } else if item.index < 9 {
                Text("⌘\(item.index + 1)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(rowBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Rename Tab…", action: onRename)
            Divider()
            Button("Close Tab", action: onClose)
        }
    }

    private var rowBackground: Color {
        if item.isSelected {
            return Color.accentColor.opacity(0.22)
        }

        if isHovering {
            return Color.primary.opacity(0.06)
        }

        return .clear
    }
}

@MainActor
private final class VerticalTabSidebarModel: ObservableObject {
    final class Item: Identifiable {
        let id: ObjectIdentifier
        weak var window: NSWindow?
        let title: String
        let subtitle: String
        let index: Int
        let isSelected: Bool

        init(window: NSWindow, title: String, subtitle: String, index: Int, isSelected: Bool) {
            self.id = ObjectIdentifier(window)
            self.window = window
            self.title = title
            self.subtitle = subtitle
            self.index = index
            self.isSelected = isSelected
        }
    }

    @Published private(set) var items: [Item] = []

    private weak var referenceWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []
    private var surfaceCancellables: Set<AnyCancellable> = []

    func connect(to window: NSWindow?) {
        disconnect()
        referenceWindow = window

        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didUpdateNotification,
            NSWindow.willCloseNotification,
            TerminalWindow.terminalDidAwake,
        ]

        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.scheduleRefresh()
                }
            }
        }

        refresh()
    }

    func disconnect() {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
        surfaceCancellables.removeAll()
        referenceWindow = nil
    }

    func select(_ item: Item) {
        item.window?.makeKeyAndOrderFront(nil)
        scheduleRefresh()
    }

    func close(_ item: Item) {
        guard let controller = item.window?.windowController as? TerminalController else { return }
        controller.closeTab(nil)
        scheduleRefresh()
    }

    func rename(_ item: Item) {
        guard let controller = item.window?.windowController as? TerminalController else { return }
        controller.promptTabTitle()
    }

    func createTab() {
        guard let controller = selectedController ?? (referenceWindow?.windowController as? TerminalController),
              let surface = controller.focusedSurface?.surface else { return }
        controller.ghostty.newTab(surface: surface)
        scheduleRefresh()
    }

    private var selectedController: TerminalController? {
        referenceWindow?.tabGroup?.selectedWindow?.windowController as? TerminalController
    }

    private func scheduleRefresh() {
        DispatchQueue.main.async { [weak self] in
            self?.refresh()
        }
    }

    private func refresh() {
        guard let referenceWindow else {
            items = []
            return
        }

        let windows = referenceWindow.tabGroup?.windows ?? [referenceWindow]
        let selectedWindow = referenceWindow.tabGroup?.selectedWindow ?? referenceWindow

        items = windows.enumerated().map { index, window in
            let controller = window.windowController as? TerminalController
            let pwd = controller?.focusedSurface?.pwd ?? ""
            let subtitle = (pwd as NSString).abbreviatingWithTildeInPath

            return Item(
                window: window,
                title: window.title,
                subtitle: subtitle,
                index: index,
                isSelected: window === selectedWindow
            )
        }

        observeSurfaceChanges(in: windows)
    }

    private func observeSurfaceChanges(in windows: [NSWindow]) {
        surfaceCancellables.removeAll()

        for window in windows {
            guard let controller = window.windowController as? TerminalController else { continue }
            for surface in controller.surfaceTree {
                surface.$pwd
                    .dropFirst()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in self?.scheduleRefresh() }
                    .store(in: &surfaceCancellables)
            }
        }
    }
}
