# Alterações de 23 de agosto de 2026

## 3DO

O core Opera não faz parte mais dos fontes do projeto, mas bundles antigos ainda podiam aparecer quando estavam instalados no Mac. A seleção de core do 3DO agora ignora explicitamente `org.openemu.Opera`. Preferências antigas que apontem para esse identificador também não conseguem mais escolhê-lo como core padrão.

## Mupen64Plus

O `Mupen64Plus/Info.plist` já declara suporte a `OEGameCoreSupportsCheatSearch`. A revisão de atualização dos cores embutidos foi incrementada para `20260823.1`, forçando a atualização de uma instalação antiga que ainda não contenha essa declaração.

## Arquivos alterados

- `OpenEmu/OEGameDocument.swift`
- `OpenEmu/GameControlsBar.swift`
- `OpenEmu/AppDelegate.swift`

## Verificação

O build do projeto foi concluído com sucesso em 23/08/2026, sem erros de compilação. O Xcode reportou apenas avisos já existentes sobre APIs depreciadas e capturas `weak`.

## Backup

Uma cópia dos arquivos relevantes foi criada em:

`Backups/2026-08-23-3do-mupen-cheat-search/`

## Pacote distribuível

O ZIP gerado a partir do archive do Xcode foi validado e contém o app com 35 cores. O app principal é universal (Intel + arm64), enquanto os cores são arm64, portanto o pacote é destinado principalmente a Macs Apple Silicon.

- Pacote: `Releases/OpenEmu-Silicon-20260823-archive.zip`
- Backup do pacote: `Backups/2026-08-23-3do-mupen-cheat-search/OpenEmu-Silicon-20260823-archive.zip`
- SHA-256: `f7f1b37497f0177db878d47cc4752aa46840489eb924a3365eaef800e7d3fec9`
- Opera: ausente
- Mupen64Plus Cheat Search: habilitado
- Assinatura: ad-hoc; em outro Mac pode ser necessário usar **Abrir** pelo menu contextual na primeira execução.

## Alteração de 24 de agosto de 2026 — controles do Wii

O controle exibido nas preferências do Wii foi atualizado usando `Wii-controles-apenas-xadrez-removido.png`. A imagem mantém a proporção do asset original, usa os tamanhos 1× e 2× (500×500 e 1000×1000) e preserva transparência real.

Uma cópia dos assets substituídos foi criada em:

`Backups/2026-08-24-wii-controller-image-v3/`

O projeto foi compilado com sucesso após a alteração.

## Archive e ZIP de 24 de agosto de 2026

O Archive foi criado pelo Xcode em:

`/Users/marceloanhani/Library/Developer/Xcode/Archives/2026-08-24/OpenEmu 24-08-2026, 13.40.xcarchive`

O ZIP foi montado a partir desse Archive, com os 35 cores portáteis disponíveis:

- Pacote: `Releases/OpenEmu-Silicon-20260824-archive.zip`
- Backup: `Backups/2026-08-24-wii-controller-image-v3/OpenEmu-Silicon-20260824-archive.zip`
- SHA-256: `11a7cf999e132a68d46b3b63522584049466a8f9c57fb9460f469272ad5a8dd9`
- Tamanho: aproximadamente 224 MB
- App principal: universal Intel + arm64
- Cores incluídos: 35
- Opera: ausente

O teste estrutural do ZIP foi concluído sem erros e a assinatura ad-hoc foi validada no app montado antes da compactação. Em outro Mac, pode ser necessário usar **Abrir** pelo menu contextual na primeira execução.
