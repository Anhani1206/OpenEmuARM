// ScreenScraperDevCredentials.template.swift
// ─────────────────────────────────────────────────────────────────────────────
// SETUP INSTRUCTIONS
// ─────────────────────────────────────────────────────────────────────────────
// 1. Copy this file and rename it:
//      ScreenScraperDevCredentials.template.swift  →  ScreenScraperDevCredentials.swift
//
// 2. Fill in the developer credentials issued by screenscraper.fr:
//    https://www.screenscraper.fr/ → Developer area → My API credentials
//
// 3. ScreenScraperDevCredentials.swift is gitignored — never commit it.
// ─────────────────────────────────────────────────────────────────────────────

import Foundation

extension ScreenScraperClient {
    /// Developer application ID issued by screenscraper.fr.
    static let devID       = "anhani"
    /// Developer application password issued by screenscraper.fr.
    static let devPassword = "Queljge3kEN"
    /// Developer debug password — enables debug mode (100 uses/day max).
    static let devDebugPassword = "gCSLZT4wLE0"
}
