# Nomes dos cores de Arcade

Os nomes exibidos na janela **Cores**, no menu **Play With…** e em
**System Files** usam a mesma apresentação limpa.

| Core | Nome exibido |
|---|---|
| FBNeo nativo | FBNeo |
| FinalBurn Neo via RetroArch | não exibido |
| MAME nativo | MAME |
| MAME 2003 | MAME 2003 (ROMset 0.78) |
| MAME 2003 Plus | MAME 2003-Plus |
| MAME 2010 | MAME 2010 (0.139) |

O sufixo técnico **(RetroArch)** foi removido da apresentação dos cores de
Arcade. Os bundle identifiers, arquivos `.info`, seleção persistida e
carregamento dos plugins continuam inalterados.

No **System Files**, as entradas `neogeo.zip` agora aparecem uma única vez,
mesmo quando o FBNeo nativo e uma variante libretro estão instalados. Isso
evita dois grupos para o mesmo BIOS e mantém o nome **Neo Geo BIOS (FBNeo)**.

O menu contextual **Play With…** usa a mesma normalização para Arcade e Neo
Geo, removendo “(RetroArch)” sem alterar os plugins selecionáveis.

O **FBNeo nativo** é o único core da família FinalBurn exibido para Arcade e
para jogos Neo Geo em `.zip`. A variante FinalBurn Neo via RetroArch,
incluindo o subconjunto Neo Geo, não é exibida nos menus.

Para Neo Geo, a seleção depende do formato: arquivos `.neo` exibem somente o
**Geolith**; arquivos `.zip` exibem somente o **FBNeo**. Essa regra é aplicada
nos menus **Default Core**, **Play With…** e **Select Core**. O menu **Default
Core** do sistema Neo Geo exibe as duas opções válidas, pois não está associado
a um jogo específico.

O projeto foi compilado com sucesso em 01/09/2026, sem erros.
