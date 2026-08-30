# Game Mode no OpenEmu

Em 27 de agosto de 2026, o target principal passou a declarar suporte ao
Game Mode do macOS por meio de `LSSupportsGameMode = YES` no Info.plist.

O macOS ativa o Game Mode automaticamente quando o aplicativo compatível entra
no modo de tela cheia nativo. O sistema prioriza CPU e GPU para o jogo e pode
reduzir a latência de controles e áudio Bluetooth. O aplicativo não controla
manualmente esses níveis de prioridade.

Esta alteração não muda o nome `OpenEmu.app`, o bundle identifier, a biblioteca,
os saves ou os caminhos de dados do aplicativo.

Referências:

- https://developer.apple.com/documentation/bundleresources/information-property-list/lssupportsgamemode
- https://support.apple.com/en-asia/105118
