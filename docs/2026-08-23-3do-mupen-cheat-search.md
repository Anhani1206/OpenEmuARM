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
