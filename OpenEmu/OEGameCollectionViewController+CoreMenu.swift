// Copyright (c) 2026, OpenEmu Team
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
import OpenEmuKit

extension OEGameCollectionViewController {

    @objc(showInformation:)
    func showInformation(_ sender: Any?) {
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

        let systemIdentifier = game.system?.systemIdentifier
        var availableCores = game.system.map {
            OECorePlugin.corePlugins(forSystemIdentifier: $0.systemIdentifier)
                .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        } ?? []

        // Match the same selection order used when opening a game: a per-game
        // choice wins, followed by the system default, followed by the first
        // compatible non-RetroArch core.
        let perGameCoreID = UserDefaults.standard.string(forKey: "openemu.gameCore.(\(game.permanentIDURI.absoluteString))")
        let systemCoreID = systemIdentifier.flatMap { UserDefaults.standard.string(forKey: "defaultCore.\($0)") }
        let selectedCoreID = perGameCoreID ?? systemCoreID
        let selectionSource: String
        let selectedCore: OECorePlugin?

        if let selectedCoreID,
           let storedCore = availableCores.first(where: { $0.bundleIdentifier.caseInsensitiveCompare(selectedCoreID) == .orderedSame }) {
            selectedCore = storedCore
            selectionSource = perGameCoreID != nil ? NSLocalizedString("per-game selection", comment: "ROM information core source") : NSLocalizedString("system default", comment: "ROM information core source")
        } else {
            var automaticCandidates = availableCores
            if systemIdentifier == "openemu.system.3do" {
                automaticCandidates.removeAll { $0.bundleIdentifier == "org.openemu.Opera" }
            }
            automaticCandidates.sort {
                let lhsRetroArch = $0.bundleIdentifier.hasSuffix("-RetroArch")
                let rhsRetroArch = $1.bundleIdentifier.hasSuffix("-RetroArch")
                if lhsRetroArch != rhsRetroArch { return !lhsRetroArch }
                return $0.displayName.caseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            selectedCore = automaticCandidates.first
            selectionSource = NSLocalizedString("automatic selection", comment: "ROM information core source")
        }

        let coreText: String
        if let selectedCore {
            coreText = String(format: NSLocalizedString("%@ (%@)\nAvailable: %@", comment: "ROM information core details"),
                              selectedCore.displayName,
                              selectionSource,
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
            String(format: NSLocalizedString("Core used to open: %@", comment: "ROM information field"), coreText),
            String(format: NSLocalizedString("Location: %@", comment: "ROM information field"), fileURL?.path ?? NSLocalizedString("Unavailable", comment: "Unavailable metadata"))
        ].joined(separator: "\n")

        let alert = NSAlert()
        alert.messageText = game.displayName
        alert.informativeText = details
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))

        // Keep the standard OpenEmuARM alert icon on the left and place the
        // game's cover art in the otherwise unused upper-right area.
        if let coverArt = game.boxImage?.image,
           let contentView = alert.window.contentView {
            let coverView = NSImageView(frame: NSRect(x: contentView.bounds.width - 112,
                                                       y: contentView.bounds.height - 112,
                                                       width: 88,
                                                       height: 88))
            coverView.image = coverArt
            coverView.imageScaling = .scaleProportionallyUpOrDown
            coverView.imageAlignment = .alignCenter
            coverView.autoresizingMask = [.minXMargin, .minYMargin]
            contentView.addSubview(coverView)
        }
        alert.runModal()
    }

    private func oeDisplayName(for plugin: OECorePlugin, systemID: String) -> String {
        guard systemID == "openemu.system.arcade" || systemID == "openemu.system.neogeo" else {
            return plugin.displayName
        }

        let name = plugin.displayName
        let normalized = name.lowercased()
        if systemID == "openemu.system.neogeo" {
            if normalized.contains("geolith") { return "Geolith" }
            if normalized.contains("fbneo") { return "FBNeo" }
        }
        if normalized.contains("finalburn neo") {
            return "FinalBurn Neo"
        }
        return name
            .replacingOccurrences(of: " (RetroArch)", with: "")
            .replacingOccurrences(of: "MAME 2003 (0.78)", with: "MAME 2003 (ROMSet 0.78)")
    }

    /// Builds a sorted "Play With…" submenu listing every installed core for the game's system.
    /// Returns nil when fewer than two cores are available (menu item is hidden in that case).
    @objc func oe_coreMenu(for game: OEDBGame) -> NSMenu? {
        guard let systemID = game.system?.systemIdentifier else { return nil }
        var plugins = OECorePlugin.corePlugins(forSystemIdentifier: systemID)
        if systemID == "openemu.system.arcade" {
            plugins.removeAll { plugin in
                let name = plugin.displayName.lowercased()
                return name.contains("finalburn neo") && !name.contains("fbneo")
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
                return !plugin.displayName.localizedCaseInsensitiveContains("fbneo")
            }
            let geolithPlugins = plugins.filter {
                $0.displayName.localizedCaseInsensitiveContains("geolith")
            }
            if geolithPlugins.count > 1 {
                let preferred = geolithPlugins.first(where: {
                    $0.bundleIdentifier == "org.openemu.Geolith"
                }) ?? geolithPlugins[0]
                plugins.removeAll {
                    $0.displayName.localizedCaseInsensitiveContains("geolith")
                }
                plugins.append(preferred)
            }
        }
        guard plugins.count > 1 else { return nil }
        plugins.sort {
            oeDisplayName(for: $0, systemID: systemID)
                .localizedStandardCompare(oeDisplayName(for: $1, systemID: systemID)) == .orderedAscending
        }
        let menu = NSMenu()
        for plugin in plugins {
            let item = NSMenuItem(title: oeDisplayName(for: plugin, systemID: systemID),
                                  action: #selector(LibraryController.startSelectedGame(withCore:)),
                                  keyEquivalent: "")
            item.representedObject = plugin
            menu.addItem(item)
        }
        return menu
    }
}
