import AppKit
import ServiceManagement

if CommandLine.arguments.contains("--unregister") {
    do {
        try SMAppService.mainApp.unregister()
        print("login item removed")
        exit(0)
    } catch {
        FileHandle.standardError.write(Data("could not remove login item: \(error.localizedDescription)\n".utf8))
        exit(1)
    }
}

if let bundleID = Bundle.main.bundleIdentifier {
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    if !others.isEmpty { exit(0) }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var tabsItem: NSStatusItem!
    var routinesItem: NSStatusItem!
    let tabsMenu = NSMenu()
    let routinesMenu = NSMenu()
    let fm = FileManager.default
    let home = FileManager.default.homeDirectoryForCurrentUser
    var tabsDir: URL { home.appendingPathComponent("tabs") }
    var routinesDir: URL { home.appendingPathComponent("routines") }
    var cli: URL { home.appendingPathComponent("tools/tabs") }

    func applicationDidFinishLaunching(_ note: Notification) {
        routinesItem = makeStatusItem(symbol: "hammer.fill", label: "Routines", menu: routinesMenu)
        tabsItem = makeStatusItem(symbol: "rectangle.stack", label: "Tab groups", menu: tabsMenu)
        if SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()
        }
    }

    func makeStatusItem(symbol: String, label: String, menu: NSMenu) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        }
        menu.delegate = self
        item.menu = menu
        return item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if menu === tabsMenu {
            let groups = listDir(tabsDir).filter { $0.pathExtension == "txt" }
            if groups.isEmpty {
                menu.addItem(withTitle: "No groups in ~/tabs", action: nil, keyEquivalent: "")
            }
            for url in groups {
                let name = url.deletingPathExtension().lastPathComponent
                let item = makeItem(name, #selector(openGroup(_:)))
                item.representedObject = name
                menu.addItem(item)
            }
            menu.addItem(.separator())
            menu.addItem(makeItem("Close all tabs", #selector(closeAll)))
            menu.addItem(makeItem("Save open tabs as group…", #selector(saveOpenTabs)))
            menu.addItem(makeItem("Edit groups", #selector(editGroups)))
        } else {
            let routines = listDir(routinesDir).filter { isExecutableFile($0) }
            if routines.isEmpty {
                menu.addItem(withTitle: "No routines in ~/routines", action: nil, keyEquivalent: "")
            }
            for url in routines {
                let item = makeItem(url.deletingPathExtension().lastPathComponent, #selector(runRoutine(_:)))
                item.representedObject = url
                menu.addItem(item)
            }
            menu.addItem(.separator())
            menu.addItem(makeItem("Edit routines", #selector(editRoutines)))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
    }

    func listDir(_ dir: URL) -> [URL] {
        ((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    func isExecutableFile(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else { return false }
        return fm.isExecutableFile(atPath: url.path)
    }

    func makeItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc func openGroup(_ sender: NSMenuItem) {
        guard let group = sender.representedObject as? String else { return }
        runCLI([group])
    }

    @objc func closeAll() {
        runCLI(["clear"])
    }

    @objc func editGroups() {
        NSWorkspace.shared.open(tabsDir)
    }

    @objc func editRoutines() {
        NSWorkspace.shared.open(routinesDir)
    }

    @objc func runRoutine(_ sender: NSMenuItem) {
        guard let script = sender.representedObject as? URL else { return }
        run(script, [], name: script.lastPathComponent)
    }

    @objc func saveOpenTabs() {
        let alert = NSAlert()
        alert.messageText = "Save open tabs as group"
        alert.informativeText = "Writes every open Chrome tab to a new file in ~/tabs."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 230, height: 24))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        field.stringValue = formatter.string(from: Date())
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "/", with: "-")
        guard !name.isEmpty else { return }
        runCLI(["save", name])
    }

    func runCLI(_ args: [String]) {
        run(cli, args, name: "tabs " + args.joined(separator: " "))
    }

    func run(_ executable: URL, _ args: [String], name: String) {
        let process = Process()
        process.executableURL = executable
        process.arguments = args
        process.currentDirectoryURL = home
        let errPipe = Pipe()
        process.standardError = errPipe
        process.terminationHandler = { finished in
            guard finished.terminationStatus != 0 else { return }
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async {
                self.showError("Failed: \(name)", stderr.isEmpty ? "exit \(finished.terminationStatus)" : stderr)
            }
        }
        do {
            try process.run()
        } catch {
            showError("Could not run \(name)", error.localizedDescription)
        }
    }

    func showError(_ message: String, _ detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
