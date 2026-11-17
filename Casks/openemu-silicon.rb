cask "openemu-silicon" do
  version "2.2.0"
  sha256 "96d7c4f5b79e552d1f41e36ca5436027a6f1b018b8d388dc85c283319da5b6b4"

  url "https://github.com/Anhani1206/OpenEmuARM/releases/download/v#{version}/OpenEmu-Silicon.dmg"
  name "OpenEmu Silicon"
  desc "Native Apple Silicon port of the OpenEmu multi-system emulator"
  homepage "https://github.com/Anhani1206/OpenEmuARM"

  livecheck do
    url "https://raw.githubusercontent.com/Anhani1206/OpenEmuARM/main/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :big_sur

  app "OpenEmu.app"

  zap trash: [
    "~/Library/Application Support/OpenEmu",
    "~/Library/Application Support/org.openemu.OEXPCCAgent.Agents",
    "~/Library/Caches/org.openemu.OpenEmu",
    "~/Library/HTTPStorages/org.openemu.OpenEmu",
    "~/Library/HTTPStorages/org.openemu.OpenEmu.binarycookies",
    "~/Library/Preferences/org.openemu.OpenEmu.plist",
    "~/Library/Saved Application State/org.openemu.OpenEmu.savedState",
  ]
end
