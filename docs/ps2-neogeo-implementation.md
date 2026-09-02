# PlayStation 2 e Neo Geo no OpenEmu-Silicon

Este guia registra as integrações de PlayStation 2 e Neo Geo concluídas no
OpenEmu-Silicon, seus requisitos e os pontos que precisam continuar sendo
preservados em alterações futuras.

## PlayStation 2 (ARMSX2)

O PlayStation 2 é disponibilizado pelo core experimental **ARMSX2**, nativo
em Apple Silicon (`arm64`). Ele é carregado como `ARMSX2.oecoreplugin` e usa
Metal diretamente, sem Rosetta no caminho normal.

### Componentes

| Componente | Responsabilidade |
|---|---|
| `ARMSX2-Core/` | Código do emulador, wrapper libretro e renderizador Metal. |
| `ARMSX2.oecoreplugin` | Bundle Release empacotado no app e instalado em `~/Library/Application Support/OpenEmu/Cores/`. |
| `OEPS2SystemController` | Sistema, controles DualShock 2 e arquivo de BIOS exibidos pelo OpenEmu. |
| `Scripts/build-armsx2-libretro-arm64.sh` | Build arm64 do core e das bibliotecas Metal. |
| `Scripts/install-debug-armsx2-core.sh` | Instalação segura do core Debug. |
| `Scripts/build-geolith-openemu-arm64.sh` | Build Release arm64 e empacotamento portátil do Geolith. |

### Configuração do usuário

1. Em **Preferences > Cores**, habilite ARMSX2 para PlayStation 2.
2. Em **Preferences > System Files**, importe um dump de BIOS de PS2 obtido
   legalmente. O core declara, entre outras, `scph10000.bin`, `scph39001.bin`
   e `scph70004.bin`.
3. Importe imagens de disco PS2 suportadas, como `.iso`.

### Build para desempenho

Use **Release** para jogar. A variante `Debug` preserva símbolos, asserts e
verificações internas do PCSX2/ARMSX2, o que pode reduzir muito o FPS e causar
áudio entrecortado. Gere e instale a variante otimizada com:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
CONFIGURATION=Release ./Scripts/build-armsx2-libretro-arm64.sh
./Scripts/install-core.sh ARMSX2 --release
./Scripts/verify-core-installed.sh ARMSX2 --release
```

### Validação de desempenho — 2026-08-31

O ARMSX2 foi recompilado em `Release` e instalado no diretório de cores do
OpenEmu. A verificação confirmou que o bundle instalado corresponde exatamente
ao produto gerado, com wrapper e biblioteca libretro em `arm64`. A execução de
teste confirmou que o desempenho e o áudio estão normais; a variante `Debug`
deve ser usada somente para diagnóstico.

### Correções importantes da integração Metal

O vídeo preto inicial foi resolvido no caminho Metal do ARMSX2:

- o wrapper registra callbacks Metal com o core;
- `GSDeviceMTL` usa o `MTLDevice` e a `MTLTexture` fornecidos pelo OpenEmu;
- a apresentação é codificada diretamente nessa textura;
- o fallback de vídeo por CPU é suprimido somente depois de existir uma
  apresentação Metal válida;
- a conclusão da apresentação mantém um fallback de cópia da textura Metal
  para o buffer de vídeo. Embora esse caminho tenha custo, ele é necessário
  para a sincronização confiável entre a thread GS alternativa do ARMSX2 e a
  apresentação do OpenEmu; removê-lo reintroduz tela preta;
- logs de apresentação Metal são limitados aos primeiros frames e depois a
  cada 60 frames. Registrar cada frame no disco reduz drasticamente o FPS e
  causa áudio entrecortado;
- para a thread GS alternativa, o fluxo de apresentação deve permanecer
  pareado como `willExecute` → conclusão do command buffer Metal →
  `didExecute`. A versão de referência em `/Users/marceloanhani/OpenEmu`
  confirmou que callbacks assíncronos nesse ponto prejudicam o ritmo de vídeo
  e áudio.
- `default.metallib`, `Metal22.metallib` e `Metal23.metallib` são atualizados
  nos recursos persistentes de ARMSX2 antes do boot. O aplicativo faz essa
  sincronização automaticamente na primeira execução, usando os arquivos
  presentes no bundle do core; uma distribuição nova não depende mais de uma
  instalação de desenvolvimento anterior.
- `GameIndex.yaml` também é copiado para os recursos persistentes no primeiro
  arranque. Sem ele, alguns jogos podem falhar com o alerta genérico de que o
  emulador não conseguiu carregar a ROM, apesar de o core e a BIOS estarem
  instalados corretamente.
- Uma BIOS PS2 importada em **System Files** é sincronizada para
  `ARMSX2/system/pcsx2/bios`, que é onde o emulador procura o firmware. Isso
  evita que uma instalação nova tenha a BIOS marcada como disponível no painel,
  mas falhe ao iniciar o jogo.

No log, uma sessão funcional deve chegar a mensagens equivalentes a:

```text
[ARMSX2-GSDeviceMTL] Using OpenEmu Metal device.
[ARMSX2-GSDeviceMTL] OpenEmu present encoding frame=1.
```

Essas mensagens confirmam que o core criou o dispositivo e codificou pelo
menos um quadro para a textura do OpenEmu. O primeiro quadro do emulador pode
ser preto durante o boot; ele não deve permanecer preto depois que o jogo
inicia.

### Diagnóstico de vídeo

Para obter o log do processo pelo Terminal:

```sh
log stream --style compact --predicate 'process == "OpenEmu" OR process == "OpenEmuHelperApp"' \
  | grep --line-buffered ARMSX2
```

Use o log para verificar, nesta ordem: registro de callbacks, carregamento de
`Metal23.metallib`, criação do dispositivo Metal, inicialização da VM e
`OpenEmu present encoding frame`.

### Validação mínima

Depois de alterar o core, compile, instale e confira o plugin instalado:

```sh
./Scripts/verify.sh --core ARMSX2
./Scripts/verify-core-installed.sh ARMSX2
```

Consulte também [ARMSX2_OPENEMU_INTEGRATION.md](../ARMSX2_OPENEMU_INTEGRATION.md)
e [ARMSX2_IMPLEMENTACAO_TECNICA.md](../ARMSX2_IMPLEMENTACAO_TECNICA.md) para
o inventário técnico completo.

## Neo Geo

Neo Geo é uma biblioteca própria no OpenEmu: os jogos não precisam aparecer
misturados na coleção **Arcade**. A coleção AES/MVS é pequena (101 jogos), mas
as ROMs usam o mesmo formato, shortnames e hashes que os ecossistemas
arcade MAME/FBNeo.

### Arquitetura

| Camada | Implementação |
|---|---|
| Sistema exibido | `openemu.system.neogeo`, nome **Neo Geo**. |
| Perfil interno | `OESystemTypeArcade` e `OESystemMediaArcadeROM`. |
| Controles | O plugin final preserva `OEArcadeSystemResponder`, com A–D, direções, Start e Coin. |
| Core | **FBNeo/FinalBurn Neo** é o único core exposto pela biblioteca Neo Geo. Os demais cores permanecem disponíveis apenas em Arcade. |
| BIOS | `OpenEmu/BIOS/fbneo/neogeo.zip`, sincronizada para `OpenEmu/FBNeo/system/neogeo.zip` e `OpenEmu/MAME/system/neogeo.zip`. |
| Identificação | Neo Geo usa o catálogo Neo Geo AES/MVS do ScreenScraper e o diretório `SNK - Neo Geo` do libretro. A base OpenVGDB é consultada com o índice Arcade, apenas para resolver shortnames e capas. |

Usar o índice Arcade não altera a biblioteca escolhida pelo usuário: um jogo
importado como Neo Geo continua na seção Neo Geo.

### Plugin final e controles

O Neo Geo é uma biblioteca separada, mas utiliza o contrato técnico do Arcade.
O `OEArcadeSystemResponder` não pode ser substituído por uma classe vazia: ele
é quem encaminha botões, créditos e início de partida ao helper. Sem ele, os
jogos podem abrir a tela de boot e ficar pretos ou encerrar ao receber input.

Por isso, a solução oficial é gerar o plugin Neo Geo ao final do build a partir
do plugin Arcade já compilado. O script
`Scripts/build-neogeo-system-plugin.sh` mantém o executável e os mapeamentos
do Arcade, altera a identidade para `openemu.system.neogeo` e reaproveita os
assets Neo Geo quando disponíveis.

O target `NeoGeo` existe apenas para compilar o catálogo de imagens. A fase
final de build substitui o seu plugin temporário pelo plugin derivado do
Arcade.

No target **OpenEmu**, mantenha uma fase **Run Script** após **Copy System
Plugins to App Plugins**, com este conteúdo:

```sh
OUTPUT_DIR="${BUILT_PRODUCTS_DIR}" \
OPENEMU_APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}" \
"${SRCROOT}/../Scripts/build-neogeo-system-plugin.sh" "${CONFIGURATION}"
```

Essa fase é obrigatória tanto para Debug quanto para Release. Executar o script
manual antes de clicar em Run não basta, pois o Xcode copia o plugin temporário
novamente durante o build.

### BIOS e ROMs

1. Mantenha cada jogo em um `.zip`; não extraia os arquivos.
2. Importe `neogeo.zip` em **Preferences > System Files** na entrada
   **Neo Geo BIOS (FBNeo)**.
3. Use ROMs e BIOS do mesmo romset do core selecionado.
4. Ao importar, escolha **Neo Geo** quando OpenEmu perguntar entre Arcade e
   Neo Geo.

As ROMs Neo Geo devem permanecer em seu `.zip` original, como no Arcade. Não
extraia os arquivos: o FBNeo usa os nomes internos do romset para localizar as
dependências.

### BIOS com o core FBNeo nativo

O bundle nativo `org.openemu.FBNeo` não declara `neogeo.zip` no seu próprio
`Info.plist`. O aplicativo adiciona essa exigência de compatibilidade quando
esse core está instalado: **System Files** mostra **Neo Geo BIOS (FBNeo)** e o
início de um jogo Neo Geo é interrompido de forma clara se o arquivo estiver
ausente. A BIOS é importada para `BIOS/fbneo/neogeo.zip` e então sincronizada
para o diretório de sistema usado pelo core nativo.

Essa regra evita que uma distribuição com FBNeo nativo pareça pronta, mas
falhe depois com uma mensagem pouco clara de ROM set. Não a remova ao alterar
o fluxo de cores ou de BIOS.

### Distribuição validada

Em 21 de agosto de 2026, foi validada uma distribuição arm64 que contém:

- `FBNeo.oecoreplugin`, usado por Arcade e Neo Geo;
- `ARMSX2.oecoreplugin`, usado por PlayStation 2;
- os plugins de sistema Neo Geo e PlayStation 2;
- a entrada **Neo Geo BIOS (FBNeo)** em **System Files**, fornecida pela
  compatibilidade acima.

PokeMini e Commodore 64 não fazem parte dessa distribuição. O pacote deve ser
criado a partir de um Archive novo, pois acrescentar os cores diretamente ao
arquivo ZIP sem criar um Archive posterior deixa as mudanças do aplicativo de
fora.

O ZIP de referência local é:

`Distribution/OpenEmu-ARM64-PS2-NeoGeo-BIOS-20260821-172112/OpenEmu-ARM64-PS2-NeoGeo-BIOS.zip`

Ele foi testado com sucesso. A BIOS `neogeo.zip` não é incluída no ZIP: deve
ser importada pelo utilizador em **Preferences > System Files**.


### Títulos e capas

Os ZIPs de Neo Geo normalmente têm nomes técnicos, por exemplo `2020bb.zip`.
Para convertê-los em títulos e capas:

- ScreenScraper usa o sistema Neo Geo AES/MVS;
- as miniaturas libretro usam `SNK - Neo Geo`;
- a consulta local OpenVGDB usa `openemu.system.arcade`, que contém os hashes
  e shortnames de ROMs arcade.

Após instalar uma versão que inclua esse mapeamento, reimporte os itens pelo
painel **Resolve Issues**: selecione os jogos, escolha **Neo Geo** em
**Import Into** e clique **Apply**. Registros já processados não são
enriquecidos automaticamente.

### Recursos visuais

O alvo NeoGeo contém os recursos abaixo:

- `neogeo_icon`: ícone pequeno e transparente da barra lateral;
- `controller_arcade`: ilustração transparente do controle Neo Geo em
  **Preferences > Controls**;
- `controller_arcade_mask`: máscara usada para realçar mapeamentos.

Os recursos devem permanecer no catálogo de imagens do alvo NeoGeo, com esses
nomes. Imagens com fundo branco não devem ser usadas: prejudicam tanto o fundo
de madeira da tela de controles quanto a aparência compacta do ícone lateral.

### Validação mínima

1. O sistema aparece na barra lateral e em **Preferences > Controls**.
2. `neogeo.zip` é aceito em **System Files**.
3. Um ZIP importado como Neo Geo recebe título e capa.
4. O jogo inicia com FinalBurn Neo mantendo o `.zip` original, aceita Coin e
   Start e não fica preto depois do boot.
5. A imagem do controle aparece sem retângulo branco.

Para os detalhes de instalação do core FBNeo, consulte
[fbneo-neogeo.md](fbneo-neogeo.md).

## Distribuição portátil do PlayStation 2

O binário `armsx2_libretro.dylib` é compilado com bibliotecas do Homebrew. Uma
distribuição que mantenha caminhos como `/opt/homebrew/opt/...` só funciona em
máquinas que também tenham essas bibliotecas instaladas, ainda que a BIOS e a
ROM do PS2 estejam corretas. O sintoma no OpenEmu é a mensagem genérica de que
a ROM não pôde ser carregada.

Antes de criar o ZIP final, execute:

```sh
./Scripts/bundle-armsx2-dependencies.sh \
  "<OpenEmu.app>/Contents/PlugIns/Cores/ARMSX2.oecoreplugin"
codesign --force --deep --sign - "<OpenEmu.app>"
```

O script copia a cadeia de bibliotecas Homebrew para
`ARMSX2.oecoreplugin/Contents/Frameworks`, altera os caminhos de carregamento
para essas cópias e assina o core. A assinatura do aplicativo completo é
reaplicada em seguida.

O fluxo oficial `Scripts/release.sh` executa essa sequência automaticamente
depois do Archive: compila ARMSX2 em Release, substitui o core no Archive e
executa `bundle-armsx2-dependencies.sh`. Caso a entrada PlayStation 2 ou o
core Release esteja ausente, o release falha em vez de publicar um aplicativo
com PS2 incompleto.

Verificação obrigatória antes de distribuir:

```sh
otool -L "<OpenEmu.app>/Contents/PlugIns/Cores/ARMSX2.oecoreplugin/Contents/Resources/armsx2_libretro.dylib" \
  | grep '/opt/homebrew' && exit 1 || true
codesign --verify --deep --strict --verbose=2 "<OpenEmu.app>"
```

Em 21 de agosto de 2026, o pacote portátil de referência foi criado em
`Distribution/OpenEmu-ARM64-Portable-PS2-v2-20260821-204923/`. Ele inclui as
dependências do PS2, inclusive as dependências `@rpath` transitivas como
`libsharpyuv.0.dylib`, continua excluindo PokeMini e Commodore 64 e pode ser
copiado para `/Applications` em outro Mac Apple Silicon sem instalar Homebrew.

No primeiro arranque do PS2 pode surgir um flash rosa muito breve, antes do
primeiro frame do jogo. Foi validado como transitório e não afeta a execução;
fica registrado como refinamento visual futuro, não como bloqueio de release.
