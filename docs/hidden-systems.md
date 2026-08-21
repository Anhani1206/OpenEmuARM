# Hidden systems in this build

PokeMini (`openemu.system.pokemini`) and Commodore 64 (`openemu.system.c64`) are intentionally hidden from the user interface.

They do not appear in Library, Controls, Cores, System Files, or file-import choices. The underlying bundled assets are kept in the repository so existing Xcode project references remain valid and the application can build safely.

The System Files filter also checks the installed core's bundle identifier and display name. This covers older local core bundles that report incomplete system identifiers.
