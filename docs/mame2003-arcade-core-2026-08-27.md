# MAME 2003 no Arcade

Data: 2026-08-27

## Diagnóstico

A tela de cores do Arcade lista os cores nativos e os cores RetroArch encontrados em `~/Library/Application Support/RetroArch/cores/`. O MAME 2003 é um core de Arcade separado, destinado exclusivamente a ROM sets compatíveis com MAME 0.78.

## Backup

Antes da alteração, foi copiado `OpenEmu/PrefCoresController.swift` para:

`Backups/geolith-neogeo-2026-08-25/PrefCoresController-before-mame2003-2026-08-27.swift`

## Correção de entendimento

A issue [#706](https://github.com/OpenEmu-Silicon/OpenEmu-Silicon/issues/706) confirma que o objetivo é compatibilidade do core MAME nativo com o ROM set 0.78/2003. Não é correto criar uma opção RetroArch chamada MAME 2003 sem um binário compatível.

Foi testada uma extensão de mapeamento para `mame2003`/`mame2003_plus`, mas ela foi revertida imediatamente porque não resolve a compatibilidade e poderia exibir uma opção falsa.

## Implementação correta

O MAME 2003 permanece associado a `openemu.system.arcade`. Ele não deve ser associado a Neo Geo nem usado para arquivos `.neo`. A descoberta do arquivo `mame2003_libretro.info` usa `systemid = "mame"`, que é mapeado para Arcade.

Quando o core oficial MAME 2003 já está disponível na lista do OpenEmu, o wrapper RetroArch equivalente é ocultado do seletor. Isso evita duas entradas para o mesmo romset 0.78 e impede que uma seleção antiga aponte para o plugin errado. MAME atual, MAME 2000, MAME 2003-Plus e FinalBurn Neo continuam visíveis como cores diferentes.

## Core salvo por jogo

Depois que um jogo é carregado com sucesso, o core efetivamente usado é salvo junto ao identificador permanente do jogo na biblioteca. Nas próximas execuções, essa escolha é tentada antes do core padrão do sistema. Isso permite que cada jogo Arcade use o core compatível com seu romset — por exemplo, MAME 2003 0.78 — sem transformar essa escolha em padrão para todos os jogos.

A escolha manual em `Play With…` continua tendo prioridade e substitui a preferência anterior somente depois que o novo core consegue carregar o jogo. Falhas de carregamento não são salvas como escolhas válidas.

## Verificação

O resultado esperado é uma única opção MAME 2003 para o Arcade, carregando ROMs compatíveis com o conjunto 0.78/2003, sem duplicar o wrapper RetroArch equivalente.

## Preparação da implementação

Backup adicional criado antes de iniciar a integração do core separado:

- `Backups/geolith-neogeo-2026-08-25/MAMEGameCore-before-mame2003-2026-08-27.m`
- `Backups/geolith-neogeo-2026-08-25/MAME-Info-before-mame2003-2026-08-27.plist`

A variante 0.78/2003 será integrada como um plugin separado. O MAME atual continuará sendo construído e instalado sem alteração.

## Integração no Release

Os recursos `mame2003_libretro.dylib` e `mame2003_libretro.info` foram adicionados ao target `OpenEmu` e serão copiados para o aplicativo Release. O nome exibido foi padronizado para `MAME 2003 0.78`.

No primeiro lançamento, `PrefCoresController` copia os recursos para as pastas padrão do RetroArch, preservando arquivos que já existam. A ponte Libretro existente continua responsável por gerar o plugin OpenEmu.

## Deduplicação da lista

Quando um core RetroArch também está presente na lista oficial do OpenEmu, a tela agora mostra apenas a opção oficial equivalente. Essa regra cobre especificamente o MAME 2003; cores distintos, como MAME 2003-Plus e FinalBurn Neo (neogeo subset), continuam separados. Backup da alteração:

`Backups/geolith-neogeo-2026-08-25/PrefCoresController-before-deduplicate-arcade-cores-2026-08-27.swift`

## Seleção automática de core por ROM set

Foi definida a evolução futura da seleção de core para jogos Arcade. O OpenEmu poderá analisar o conteúdo do arquivo ZIP antes de iniciar o emulador, lendo os nomes dos arquivos internos e seus CRCs e comparando-os com uma tabela de compatibilidade.

Prioridade planejada:

1. MAME 2003 0.78 para ROM sets compatíveis com MAME 0.78;
2. FinalBurn Neo quando o conjunto for identificado como compatível;
3. MAME atual para conjuntos modernos;
4. core padrão como fallback quando não houver correspondência segura.

O hash do ZIP completo não será usado como único critério, porque nomes, ordem e compressão podem variar sem alterar o conteúdo da ROM.

## Escolha salva por jogo

A detecção automática será usada na primeira execução. A escolha final do usuário ficará salva por jogo e será reutilizada nas execuções seguintes. O menu `Play With…` continuará permitindo trocar o core manualmente.

A preferência deverá ser associada a um identificador estável do conteúdo, preferencialmente baseado nos arquivos internos e seus CRCs, e não somente no caminho do arquivo. Se o jogo for substituído ou o core salvo deixar de existir, a detecção será refeita.

## Instalação externa

O binário ARM64 está disponível no buildbot oficial do Libretro e o arquivo `.info` oficial identifica o core como `MAME 2003 (0.78)`, com `systemid = "mame"`. A instalação automática ficou pendente porque o diretório `~/Library/Application Support/RetroArch` está fora da área de escrita autorizada desta sessão.

Com o OpenEmu fechado, a instalação pode ser feita no Terminal com:

```sh
set -e
retroarch_dir="$HOME/Library/Application Support/RetroArch"
mkdir -p "$retroarch_dir/cores" "$retroarch_dir/info"
tmp_dir="$(mktemp -d)"
curl -L --fail 'https://buildbot.libretro.com/nightly/apple/osx/arm64/latest/mame2003_libretro.dylib.zip' -o "$tmp_dir/mame2003.zip"
unzip -o "$tmp_dir/mame2003.zip" -d "$retroarch_dir/cores"
curl -L --fail 'https://raw.githubusercontent.com/libretro/libretro-core-info/master/mame2003_libretro.info' -o "$retroarch_dir/info/mame2003_libretro.info"
rm -rf "$tmp_dir"
```

Depois, abrir o OpenEmu e atualizar Preferências → Cores → Arcade. O MAME 2003 deverá aparecer como opção RetroArch, sem remover os demais cores.
