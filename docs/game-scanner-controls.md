# Controles do Game Scanner

## Importação

Durante a importação, o Game Scanner mostra os controles de pausa e parada na
mesma linha do título `Game Scanner`. Eles ficam ocultos quando não há uma fila
ativa.

Quando uma ROM não pode ser importada, o alerta apresenta os botões nesta
ordem:

- `Stop Import`: interrompe a fila restante;
- `Skip ROM`: ignora apenas a ROM atual;
- `Skip all ROM`: ignora a ROM atual e os próximos erros automaticamente.

O estado de `Skip all ROM` é limpo quando a importação termina ou é cancelada.
Os jogos importados antes da interrupção permanecem na biblioteca.

## Arquivos alterados

- `OpenEmu/GameScannerViewController.swift`
- `OpenEmu/SidebarController.xib`

Validação: o projeto compilou com sucesso em 30/08/2026.
