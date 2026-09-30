// Copyright (c) 2019, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the OpenEmu Team nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Cocoa

@objc
class GameCollectionViewController: ImageCollectionViewController {
    @IBOutlet weak var listView: GameTableView!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        Bundle(for: GameTableView.self).loadNibNamed("GameTableView", owner: self, topLevelObjects: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    
    override func validateToolbarItems() {
        guard let toolbar = toolbar else { return }
        
        let isGridView = selectedViewTag == .gridViewTag
        let isBlankSlate = shouldShowBlankSlate
        
        toolbar.viewModeSelector.isEnabled = !isBlankSlate
        toolbar.viewModeSelector.selectedSegment = isGridView ? 0 : 1
        
        toolbar.gridSizeSlider.isEnabled = isGridView && !isBlankSlate
        toolbar.decreaseGridSizeButton.isEnabled = isGridView && !isBlankSlate
        toolbar.increaseGridSizeButton.isEnabled = isGridView && !isBlankSlate
        
        toolbar.searchField.isEnabled = !isBlankSlate
        toolbar.searchField.searchMenuTemplate = nil
        toolbar.searchField.stringValue = currentSearchTerm
        
        toolbar.addButton.isEnabled = true
        
        if #available(macOS 11.0, *) {
            for item in toolbar.items {
                if item.itemIdentifier == .oeSearch {
                    item.isEnabled = !isBlankSlate
                }
            }
        }
    }
}

extension GameCollectionViewController: CollectionViewExtendedDelegate, NSMenuItemValidation {
    
    // MARK: - Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(copy(_:)),
             #selector(delete(_:)),
             #selector(showInFinder(_:)):
            return !selectedGames.isEmpty
        default:
            return true
        }
    }
    
    // MARK: - Context Menus
    
    func collectionView(_ collectionView: CollectionView, menuForItemsAt indexPaths: Set<IndexPath>) -> NSMenu? {
        let menu = NSMenu()
        var item: NSMenuItem
        let games = selectedGames
        let hasLocalFiles = games.first(where: { $0.defaultROM?.filesAvailable == true }) != nil
        
        if games.count == 1 {
            let game = games.first!
            
            menu.addItem(withTitle: NSLocalizedString("Play Game", comment: ""),
                         action: #selector(LibraryController.startSelectedGame(_:)),
                         keyEquivalent: "")
            
            if let coreSubmenu = coreMenu(for: game) {
                item = NSMenuItem()
                item.title = NSLocalizedString("Play With…", comment: "Submenu listing available cores for this system")
                item.submenu = coreSubmenu
                menu.addItem(item)
            }
            
            item = NSMenuItem()
            item.title = NSLocalizedString("Play Save State", comment: "")
            item.submenu = saveStateMenu(for: game)
            menu.addItem(item)
            
            item = NSMenuItem()
            item.title = NSLocalizedString("Delete Save State", comment: "")
            item.isAlternate = true
            item.keyEquivalentModifierMask = .option
            item.submenu = saveStateMenu(for: game)
            menu.addItem(item)
            
            menu.addItem(.separator())
            
            item = NSMenuItem()
            item.title = NSLocalizedString("Rating", comment: "")
            item.submenu = ratingMenu(for: games)
            menu.addItem(item)
            
            if hasLocalFiles {
                menu.addItem(withTitle: NSLocalizedString("Show in Finder", comment: ""),
                             action: #selector(showInFinder(_:)),
                             keyEquivalent: "")
                menu.addItem(withTitle: NSLocalizedString("Show Information…", comment: "Show ROM and core information"),
                             action: #selector(showInformation(_:)),
                             keyEquivalent: "")
            }
            
            menu.addItem(.separator())
            
            if game.status == .ok {
                menu.addItem(withTitle: NSLocalizedString("Download Cover Art", comment: ""),
                             action: #selector(downloadCoverArt(_:)),
                             keyEquivalent: "")
            }
            if game.status == .processing {
                menu.addItem(withTitle: NSLocalizedString("Cancel Cover Art Download", comment: ""),
                             action: #selector(cancelCoverArtDownload(_:)),
                             keyEquivalent: "")
            }
            menu.addItem(withTitle: NSLocalizedString("Add Cover Art from File…", comment: ""),
                         action: #selector(addCoverArtFromFile(_:)),
                         keyEquivalent: "")
            if hasLocalFiles {
                menu.addItem(withTitle: NSLocalizedString("Consolidate Files…", comment: ""),
                             action: #selector(consolidateFiles(_:)),
                             keyEquivalent: "")
            }
            
            menu.addItem(.separator())
            
            item = NSMenuItem(title: NSLocalizedString("Add to Collection", comment: ""),
                              action: nil,
                              keyEquivalent: "")
            item.submenu = collectionsMenu(for: games)
            menu.addItem(item)

            item = NSMenuItem(title: NSLocalizedString("Move to System…", comment: "Move the selected game to another console system"),
                              action: nil,
                              keyEquivalent: "")
            item.submenu = systemMenu(for: games)
            menu.addItem(item)
            
            menu.addItem(.separator())
            
            menu.addItem(withTitle: NSLocalizedString("Rename Game", comment: ""),
                         action: #selector(CollectionView.beginEditingWithSelectedItem(_:)),
                         keyEquivalent: "")
            var title: String
            if type(of: representedObject as AnyObject) === OEDBCollection.self {
                title = NSLocalizedString("Remove Game", comment: "")
            } else {
                title = NSLocalizedString("Delete Game", comment: "")
            }
            menu.addItem(withTitle: title,
                         action: #selector(deleteSelectedItems(_:)),
                         keyEquivalent: "")
        }
        else {
            // FIXME: starting multiple games only starts the first of the selected games
            /*if UserDefaults.standard.bool(forKey: OEForcePopoutGameWindowKey) {
                menu.addItem(withTitle: NSLocalizedString("Play Games (Caution)", comment: ""),
                             action: #selector(LibraryController.startSelectedGame(_:)),
                             keyEquivalent: "")
            }*/
            
            item = NSMenuItem()
            item.title = NSLocalizedString("Rating", comment: "")
            item.submenu = ratingMenu(for: games)
            menu.addItem(item)
            
            if hasLocalFiles {
                menu.addItem(withTitle: NSLocalizedString("Show in Finder", comment: ""),
                             action: #selector(showInFinder(_:)),
                             keyEquivalent: "")
            }
            
            menu.addItem(.separator())
            
            menu.addItem(withTitle: NSLocalizedString("Download Cover Art", comment: ""),
                         action: #selector(downloadCoverArt(_:)),
                         keyEquivalent: "")
            menu.addItem(withTitle: NSLocalizedString("Add Cover Art from File…", comment: ""),
                         action: #selector(addCoverArtFromFile(_:)),
                         keyEquivalent: "")
            menu.addItem(withTitle: NSLocalizedString("Consolidate Files…", comment: ""),
                         action: #selector(consolidateFiles(_:)),
                         keyEquivalent: "")
            
            menu.addItem(.separator())
            
            item = NSMenuItem(title: NSLocalizedString("Add to Collection", comment: ""),
                              action: nil,
                              keyEquivalent: "")
            item.submenu = collectionsMenu(for: games)
            menu.addItem(item)

            item = NSMenuItem(title: NSLocalizedString("Move to System…", comment: "Move the selected games to another console system"),
                              action: nil,
                              keyEquivalent: "")
            item.submenu = systemMenu(for: games)
            menu.addItem(item)
            
            menu.addItem(.separator())
            
            var title: String
            if type(of: representedObject as AnyObject) === OEDBCollection.self {
                title = NSLocalizedString("Remove Games", comment: "")
            } else {
                title = NSLocalizedString("Delete Games", comment: "")
            }
            menu.addItem(withTitle: title,
                         action: #selector(deleteSelectedItems(_:)),
                         keyEquivalent: "")
        }
        
        return menu
    }
    
    private func coreMenu(for game: OEDBGame) -> NSMenu? {
        guard let systemID = game.system?.systemIdentifier else { return nil }
        var plugins = OECorePlugin.corePlugins(forSystemIdentifier: systemID)
        if systemID == "openemu.system.arcade" {
            // The Neo Geo subset belongs only to the dedicated Neo Geo library.
            plugins.removeAll { plugin in
                let name = plugin.displayName.lowercased()
                return (name.contains("finalburn neo") || name.contains("fbneo")) &&
                    (name.contains("neogeo") || name.contains("neo geo"))
            }
        }
        if systemID == "openemu.system.neogeo" {
            let isNeoCartridge = game.roms.contains {
                $0.url?.pathExtension.caseInsensitiveCompare("neo") == .orderedSame
            }
            plugins.removeAll { plugin in
                if isNeoCartridge {
                    return !plugin.displayName.localizedCaseInsensitiveContains("geolith")
                }
                return !plugin.displayName.localizedCaseInsensitiveContains("fbneo") &&
                    !plugin.displayName.localizedCaseInsensitiveContains("finalburn neo")
            }
        }
        guard plugins.count > 1 else { return nil }

        func displayName(for plugin: OECorePlugin) -> String {
            let name = plugin.displayName
            let normalized = name.lowercased()
            let isArcadeFamily = systemID == "openemu.system.arcade" ||
                systemID == "openemu.system.neogeo"
            guard isArcadeFamily else { return name }

            if normalized.contains("finalburn neo") || normalized.contains("fbneo") {
                if normalized.contains("neogeo") || normalized.contains("neo geo") {
                    return "FinalBurn Neo (Neo Geo)"
                }
                return "FinalBurn Neo"
            }
            return name
                .replacingOccurrences(of: " (RetroArch)", with: "")
                .replacingOccurrences(of: "MAME 2003 (0.78)", with: "MAME 2003 (ROMSet 0.78)")
        }

        plugins.sort { displayName(for: $0).localizedStandardCompare(displayName(for: $1)) == .orderedAscending }
        let menu = NSMenu()
        for plugin in plugins {
            let item = NSMenuItem(title: displayName(for: plugin),
                                  action: #selector(LibraryController.startSelectedGame(withCore:)),
                                  keyEquivalent: "")
            item.representedObject = plugin
            menu.addItem(item)
        }
        return menu
    }
    
    private func saveStateMenu(for game: OEDBGame) -> NSMenu {
        let menu = NSMenu()
        
        game.roms.forEach { rom in
            
            rom.removeMissingStates()
            
            let saveStates = rom.normalSaveStatesByTimestamp(ascending: false)
            saveStates.forEach { saveState in
                
                let title = saveState.name
                
                let item = NSMenuItem()
                item.title = title
                item.action = #selector(LibraryController.startSelectedGame(saveState:))
                item.representedObject = saveState
                menu.addItem(item)
                
                let alternateItem = NSMenuItem()
                alternateItem.title = title
                alternateItem.action = #selector(deleteSaveState(_:))
                alternateItem.isAlternate = true
                alternateItem.keyEquivalentModifierMask = .option
                alternateItem.representedObject = saveState
                menu.addItem(alternateItem)
            }
        }
        
        if menu.items.isEmpty {
            menu.addItem(withTitle: NSLocalizedString("No Save States available", comment: ""),
                         action: nil,
                         keyEquivalent: "")
        }
        
        return menu
    }
    
    private func ratingMenu(for games: [OEDBGame]) -> NSMenu {
        let menu = NSMenu()
        let ratingLabel = "★★★★★"
        
        for i in 0...5 {
            let item = NSMenuItem()
            item.title = i == 0 ? NSLocalizedString("None", comment: "")
                                      : "\(ratingLabel.prefix(i))"
            item.action = #selector(setRatingForSelectedGames(_:))
            item.representedObject = i
            menu.addItem(item)
        }
        
        var valuesDiffer = false
        for i in 0..<games.count {
            let gameRating = games[i].rating
            let itemIndex = gameRating?.intValue ?? 0
            let item = menu.item(at: itemIndex)
            
            if i == 0 {
                item?.state = .on
            } else if item?.state != .on {
                valuesDiffer = true
                item?.state = .mixed
            }
        }
        
        if valuesDiffer {
            let gameRating = games.first?.rating
            let item = menu.item(at: gameRating?.intValue ?? 0)
            item?.state = .mixed
        }
        
        return menu
    }
    
    private func collectionsMenu(for games: [OEDBGame]) -> NSMenu {
        let menu = NSMenu()
        let collections = database!.collections
        
        var item = NSMenuItem()
        item.title = NSLocalizedString("New Collection from Selection", comment: "")
        item.action = #selector(LibraryGamesViewController.makeNewCollectionWithSelectedGames(_:))
        menu.addItem(item)
        
        collections.forEach { collection in
            if type(of: collection) === OEDBCollection.self,
               !collection.isEqual(representedObject) {
                item = NSMenuItem()
                item.title = (collection as! OEDBCollection).name
                item.action = #selector(addSelectedGamesToCollection(_:))
                item.representedObject = collection
                menu.addItem(item)
            }
        }
        
        if menu.items.count != 1 {
            menu.insertItem(.separator(), at: 1)
        }
        
        return menu
    }

    private func systemMenu(for games: [OEDBGame]) -> NSMenu {
        let menu = NSMenu()
        guard let context = games.first?.managedObjectContext else { return menu }

        let systems = OEDBSystem.enabledSystems(in: context)
            .filter { $0.plugin != nil }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        for system in systems {
            let item = NSMenuItem(title: system.name,
                                  action: #selector(moveSelectedGames(toSystem:)),
                                  keyEquivalent: "")
            item.representedObject = system
            item.state = games.allSatisfy { $0.system == system } ? .on : .off
            menu.addItem(item)
        }

        if menu.items.isEmpty {
            menu.addItem(withTitle: NSLocalizedString("No systems available", comment: ""),
                         action: nil,
                         keyEquivalent: "")
        }
        return menu
    }
    
    // MARK: - Actions
    
    @objc func showInFinder(_ sender: Any?) {
        let urls = selectedGames.compactMap { $0.defaultROM?.url?.absoluteURL }
        
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    @objc func showInformation(_ sender: Any?) {
        guard let game = selectedGames.first,
              let rom = game.defaultROM else { return }

        let systemName = game.system?.name ?? NSLocalizedString("Unknown", comment: "Unknown game system")
        let fileURL = rom.url?.absoluteURL
        let fileName = rom.fileName ?? fileURL?.lastPathComponent ?? NSLocalizedString("Unavailable", comment: "Unavailable metadata")
        let format = fileURL?.pathExtension.uppercased() ?? NSLocalizedString("Unknown", comment: "Unknown ROM format")
        let size = rom.fileSize?.int64Value ?? fileURL.flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.map(Int64.init)
        let sizeText = size.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
            ?? NSLocalizedString("Unavailable", comment: "Unavailable metadata")
        let checksum = rom.md5HashIfAvailable ?? NSLocalizedString("Not calculated", comment: "Checksum has not been calculated")
        let serial = rom.serial ?? NSLocalizedString("Unavailable", comment: "Unavailable metadata")

        let availableCores = game.system.map {
            OECorePlugin.corePlugins(forSystemIdentifier: $0.systemIdentifier)
                .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        } ?? []
        let defaultCoreKey = game.system.map { "defaultCore.\($0.systemIdentifier)" }
        let preferredCoreID = defaultCoreKey.flatMap { UserDefaults.standard.string(forKey: $0) }
        let preferredCore = availableCores.first { $0.bundleIdentifier.caseInsensitiveCompare(preferredCoreID ?? "") == .orderedSame }
        let coreText: String
        if let preferredCore {
            coreText = String(format: NSLocalizedString("%@ (preferred)\nAvailable: %@", comment: "ROM information core details"),
                              preferredCore.displayName,
                              availableCores.map(\.displayName).joined(separator: ", "))
        } else if availableCores.isEmpty {
            coreText = NSLocalizedString("Unavailable", comment: "Unavailable metadata")
        } else {
            coreText = String(format: NSLocalizedString("Not explicitly selected\nAvailable: %@", comment: "ROM information core details"),
                              availableCores.map(\.displayName).joined(separator: ", "))
        }

        let details = [
            String(format: NSLocalizedString("System: %@", comment: "ROM information field"), systemName),
            String(format: NSLocalizedString("Format: %@", comment: "ROM information field"), format),
            String(format: NSLocalizedString("File: %@", comment: "ROM information field"), fileName),
            String(format: NSLocalizedString("Size: %@", comment: "ROM information field"), sizeText),
            String(format: NSLocalizedString("Serial: %@", comment: "ROM information field"), serial),
            String(format: NSLocalizedString("MD5: %@", comment: "ROM information field"), checksum),
            "",
            String(format: NSLocalizedString("Core preference: %@", comment: "ROM information field"), coreText),
            String(format: NSLocalizedString("Location: %@", comment: "ROM information field"), fileURL?.path ?? NSLocalizedString("Unavailable", comment: "Unavailable metadata"))
        ].joined(separator: "\n")

        let alert = NSAlert()
        alert.messageText = game.displayName
        alert.informativeText = details
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
    }
    
    @IBAction func copy(_ sender: Any?) {
        copySelectedItems(sender)
    }
    
    @objc func copySelectedItems(_ sender: Any?) {
        let fileURLs = selectedGames.compactMap { $0.defaultROM?.url?.absoluteURL as NSURL? }
        
        let pboard = NSPasteboard.general
        pboard.clearContents()
        pboard.declareTypes([.fileURL], owner: nil)
        pboard.writeObjects(fileURLs)
    }
    
    @IBAction override func delete(_ sender: Any?) {
        deleteSelectedItems(sender)
    }
    
    @objc func deleteSelectedItems(_ sender: Any?) {
        assert(Thread.isMainThread, "Only call on main thread!")
        let multipleGames = selectedGames.count > 1
        
        // deleting from 'All Games', smart collections and consoles removes games from the library
        if representedObject is OEDBSystem ||
           representedObject is OEDBSmartCollection ||
           representedObject is OEDBAllGamesCollection {
            // delete games from library if user allows it
            if OEAlert.removeGamesFromLibrary(multipleGames: multipleGames).runModal() == .alertFirstButtonReturn {
                selectedGames.forEach { $0.delete(moveToTrash: true, keepSaveStates: false) }
                
                let context = selectedGames.last?.managedObjectContext
                try? context?.save()
                
                reloadData()
            }
        }
        // deleting from regular collections removes games from that collection
        else if let collection = representedObject as? OEDBCollection {
            // remove games from collection if user allows it
            if OEAlert.removeGamesFromCollection(multipleGames: multipleGames).runModal() == .alertFirstButtonReturn {
                collection.games.subtract(selectedGames)
                collection.save()
            }
            reloadData()
        }
    }
    
    @objc func deleteSaveState(_ sender: NSMenuItem) {
        guard let state = sender.representedObject as? OEDBSaveState else { return }
        
        let stateName = state.name
        let alert = OEAlert.deleteSaveState(name: stateName)
        
        if alert.runModal() == .alertFirstButtonReturn {
            state.deleteAndRemoveFiles()
        }
    }
    
    @objc func addSelectedGamesToCollection(_ sender: NSMenuItem) {
        assert(Thread.isMainThread, "Only call on main thread!")
        guard let collection = sender.representedObject as? OEDBCollection else { return }
        
        collection.games.formUnion(selectedGames)
        collection.save()
        
        reloadData()
    }

    @objc func moveSelectedGames(toSystem sender: NSMenuItem) {
        assert(Thread.isMainThread, "Only call on main thread!")
        guard let targetSystem = sender.representedObject as? OEDBSystem,
              let database = targetSystem.managedObjectContext?.libraryDatabase else { return }

        var failures = [String]()
        for game in selectedGames where game.system != targetSystem {
            do {
                try moveGame(game, to: targetSystem, in: database)
                game.system = targetSystem
            } catch {
                failures.append("\(game.displayName): \(error.localizedDescription)")
            }
        }

        do {
            try targetSystem.managedObjectContext?.save()
        } catch {
            failures.append(error.localizedDescription)
        }

        if !failures.isEmpty {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Could not move all selected games", comment: "")
            alert.informativeText = failures.joined(separator: "\n")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }

        reloadData()
    }

    @objc func downloadCoverArt(_ sender: Any?) {
        selectedGames.forEach { $0.requestCoverDownload() }
        selectedGames.last?.save()
        
        reloadData()
    }
    
    @objc func cancelCoverArtDownload(_ sender: Any?) {
        selectedGames.forEach { $0.cancelCoverDownload() }
        selectedGames.last?.save()
        
        reloadData()
    }
    
    @objc func addCoverArtFromFile(_ sender: Any?) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = NSImage.imageTypes
        
        openPanel.begin { result in
            guard result == .OK, let url = openPanel.url else { return }
            
            self.selectedGames.forEach { $0.setBoxImage(url: url) }
            let context = self.selectedGames.last?.managedObjectContext
            try? context?.save()
            
            self.reloadData()
        }
    }
    
    @objc func setRatingForSelectedGames(_ sender: NSMenuItem) {
        selectedGames.forEach { $0.rating = sender.representedObject as? NSNumber }
        
        reloadData()
    }
    
    @IBAction func setRatingForGame(_ sender: NSLevelIndicator) {
        guard let game = sender.cell?.representedObject as? OEDBGame else { return }
        game.rating = sender.intValue as NSNumber
        
        reloadData()
    }
    
    // untested
    @objc func consolidateFiles(_ sender: Any?) {
        DispatchQueue.main.async {
            let games = self.selectedGames
            if games.isEmpty {
                return
            }
            
            var alert = OEAlert()
            alert.messageText = NSLocalizedString("Consolidating will copy all of the selected games into the OpenEmu Library folder.", comment: "")
            alert.informativeText = NSLocalizedString("This cannot be undone.", comment: "")
            alert.defaultButtonTitle = NSLocalizedString("Consolidate", comment: "")
            alert.alternateButtonTitle = NSLocalizedString("Cancel", comment: "")
            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
            
            alert = OEAlert()
            alert.messageText = NSLocalizedString("Copying Game Files…", comment: "")
            alert.showsProgressbar = true
            alert.progress = 0
            
            var alertResult = -1
            let context = OELibraryDatabase.default!.makeWriterChildContext()
            let gameIDs = games.map { $0.permanentID }
            
            DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                context.performAndWait {
                    var err: Error?
                    for i in 0..<gameIDs.count {
                        if alertResult != -1 {
                            break
                        }
                        
                        let gameID = gameIDs[i]
                        let game = OEDBGame.object(with: gameID, in: context)
                        for rom in game?.roms ?? [] {
                            if alertResult != -1 {
                                break
                            }
                            do {
                                try rom.consolidateFiles()
                                break
                            } catch {
                                err = error
                            }
                        }
                        
                        alert.performBlockInModalSession {
                            alert.progress = Double(i + 1) / Double(games.count)
                        }
                        
                        if err != nil {
                            break
                        }
                    }
                    
                    if let error = err {
                        let originalCompletionHandler = alert.callbackHandler
                        alert.callbackHandler = { alert, result in
                            let errorAlert = OEAlert()
                            errorAlert.messageText = NSLocalizedString("Consolidating files failed.", comment: "")
                            errorAlert.informativeText = error.localizedDescription
                            errorAlert.defaultButtonTitle = NSLocalizedString("OK", comment: "")
                            errorAlert.runModal()
                            
                            if let originalCompletionHandler = originalCompletionHandler {
                                originalCompletionHandler(alert, result)
                            }
                        }
                    }
                    
                    try? context.save()
                    let writerContext = context.parent
                    writerContext?.perform {
                        writerContext?.userInfo[OELibraryDatabase.managedObjectContextHasDirectChangesUserInfoKey] = true as NSNumber
                        try? writerContext?.save()
                    }
                    
                    alert.close(withResult: .alertFirstButtonReturn)
                }
            }
            
            alert.defaultButtonTitle = NSLocalizedString("Stop", comment: "")
            alertResult = alert.runModal().rawValue
        }
    }
    
    func collectionView(_ collectionView: CollectionView, doubleClickForItemAt indexPath: IndexPath) {
        let item = dataSource.item(at: indexPath)
        NSApp.sendAction(#selector(LibraryController.startSelectedGame(_:)), to: nil, from: item)
    }
}

private func moveGame(_ game: OEDBGame, to system: OEDBSystem, in database: OELibraryDatabase) throws {
    guard let libraryFolder = database.romsFolderURL else { return }

    for rom in game.roms {
        guard let sourceURL = rom.url,
              sourceURL.isSubpath(of: libraryFolder) else { continue }

        let sourceFile = try OEFile(url: sourceURL)
        guard sourceFile.allFileURLs.count == 1 else {
            throw NSError(domain: "OpenEmuLibrary", code: 1, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("This disc image has referenced files and cannot be moved automatically.", comment: "")
            ])
        }

        var destinationFolder = database.romsFolderURL(for: system)
        let fileName = sourceURL.lastPathComponent
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        if system.plugin?.supportsDiscsWithDescriptorFile == true {
            destinationFolder = destinationFolder.appendingPathComponent(baseName, isDirectory: true)
        }
        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        var destinationURL = destinationFolder.appendingPathComponent(fileName)
        destinationURL = destinationURL.uniqueURL { count in
            let name = "\(baseName) \(count).\(sourceURL.pathExtension)"
            return destinationFolder.appendingPathComponent(name)
        }

        try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
        rom.url = destinationURL
    }
}

extension OEGameCollectionViewController {
    @objc(oe_moveToSystemMenuForGames:)
    func oe_moveToSystemMenu(forGames games: [OEDBGame]) -> NSMenu {
        let menu = NSMenu()
        guard let context = games.first?.managedObjectContext else { return menu }

        let systems = OEDBSystem.enabledSystems(in: context)
            .filter { $0.plugin != nil }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        for system in systems {
            let item = NSMenuItem(title: system.name,
                                  action: #selector(oe_moveSelectedGamesToSystem(_:)),
                                  keyEquivalent: "")
            item.representedObject = system
            item.state = games.allSatisfy { $0.system == system } ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    @objc(oe_moveSelectedGamesToSystem:)
    func oe_moveSelectedGamesToSystem(_ sender: NSMenuItem) {
        guard let targetSystem = sender.representedObject as? OEDBSystem,
              let database = targetSystem.managedObjectContext?.libraryDatabase else { return }

        var failures = [String]()
        for game in selectedGames where game.system != targetSystem {
            do {
                try moveGame(game, to: targetSystem, in: database)
                game.system = targetSystem
            } catch {
                failures.append("\(game.displayName): \(error.localizedDescription)")
            }
        }

        do {
            try targetSystem.managedObjectContext?.save()
        } catch {
            failures.append(error.localizedDescription)
        }

        if !failures.isEmpty {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Could not move all selected games", comment: "")
            alert.informativeText = failures.joined(separator: "\n")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
        reloadData()
    }
}
