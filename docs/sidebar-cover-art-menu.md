# Cover Arts no menu contextual das consoles

## Comportamento

Ao clicar com o botão direito no nome de uma console, na barra lateral, o menu apresenta o submenu `Cover Arts` com:

- `Download all Cover Arts`
- `Stop download Cover Arts`

As ações usam a console clicada como alvo e processam todos os jogos associados a ela. Elas não dependem do jogo selecionado na área principal.

O menu contextual de cada jogo também apresenta um submenu `Cover Arts`, acima de `Add Cover Art from File…`, com:

- `Download Cover Art`
- `Stop download Cover Art`

Essas ações individuais usam os jogos selecionados como alvo. As opções de adicionar capa ou importar artwork continuam no menu dos jogos.

## Implementação

- `SidebarController.swift` cria o submenu para itens `OEDBSystem` e encaminha a console pelo `representedObject`.
- `downloadAllCoverArt(_:)` solicita o download para todos os jogos da console.
- `stopAllCoverArtDownloads(_:)` cancela os downloads em andamento para todos os jogos da console.
- `OEGameCollectionViewController` mantém apenas as ações individuais já existentes.
- `OEGameCollectionViewController.m` cria o submenu individual `Cover Arts` e encaminha as ações para `requestCoverDownload` e `cancelCoverArtDownload`.

## Validação

O projeto foi compilado com sucesso em 30/08/2026 pelo `BuildProject`, sem erros.
