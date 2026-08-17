# Implementação técnica do ARMSX2 no OpenEmu

## Objetivo e escopo

Este documento descreve a rota de PlayStation 2 nativa em Apple Silicon
implementada no OpenEmu sob o nome **ARMSX2**. Ela substitui a necessidade de
executar o emulador de PS2 via Rosetta no fluxo operacional desta integração:
o core, o wrapper e o caminho de renderização são `arm64`.

O objetivo não é garantir compatibilidade total com a biblioteca de PS2. A
integração atual fornece uma base nativa, com boot, vídeo Metal e áudio
validados em um título de referência; ainda requer a matriz de testes descrita
em [Validação e pendências](#validação-e-pendências).

> Fonte integrada: `ARMSX2/ARMSX2`, commit documentado `788a59d`.
> Este repositório usa a árvore local `ARMSX2-Core/` como fonte do core.

## Arquitetura

```text
OpenEmu.app
  └─ ARMSX2.oecoreplugin (bundle do core)
       ├─ Contents/MacOS/ARMSX2
       │    └─ ARMSX2GameCore (wrapper Objective-C++)
       └─ Contents/Resources/armsx2_libretro.dylib
            └─ pcsx2-libretro/Main.cpp
                 └─ ARMSX2 / PCSX2 subsystems
                      └─ GSDeviceMTL (Metal)
                           └─ MTLDevice + MTLTexture do OpenEmu
```

O wrapper carrega a biblioteca libretro com `dlopen`, resolve os símbolos
`retro_*` obrigatórios e registra os callbacks de ambiente, vídeo, áudio e
controle. Além da API libretro padrão, ele resolve opcionalmente
`armsx2_openemu_set_metal_callbacks`, a extensão local que conecta Metal ao
OpenEmu sem uma cópia de vídeo como caminho principal.

## Arquivos que compõem a implementação

| Caminho | Responsabilidade |
|---|---|
| `ARMSX2-Core/OpenEmu/ARMSX2GameCore.h` | Declara a classe OpenEmu `ARMSX2GameCore` e sua conformidade com `OEPS2SystemResponderClient`. |
| `ARMSX2-Core/OpenEmu/ARMSX2GameCore.mm` | Wrapper principal: `dlopen`, callbacks libretro, áudio, input, diretórios persistentes, serialização e ponte Metal. |
| `ARMSX2-Core/OpenEmu/Info.plist` | Metadados de `ARMSX2.oecoreplugin`, identificador `org.openemu.ARMSX2`, sistema `openemu.system.ps2`, BIOS aceitas e dois jogadores. |
| `ARMSX2-Core/pcsx2-libretro/Main.cpp` | Libretro ARMSX2: boot da VM, renderer Metal, ciclo `retro_run` e exportação da ponte `armsx2_openemu_*`. |
| `ARMSX2-Core/pcsx2/GS/Renderers/Metal/GSDeviceMTL.mm` | Renderizador GS Metal adaptado para usar dispositivo e textura fornecidos pelo OpenEmu e apresentar diretamente nessa textura. |
| `ARMSX2-Core/pcsx2/GS/GS.cpp` | Abertura do GS; identifica a rota OpenEmu Metal e evita inicializar a interface ImGui do PCSX2 nesse caso. |
| `ARMSX2-Core/pcsx2/GS/Renderers/Metal/*.metal` | Fontes dos shaders Metal: `cas`, `convert`, `present`, `merge`, `misc`, `interlace`, `tfx` e `fxaa`. |
| `ARMSX2-Core/armsx2_libretro.info` | Metadados libretro e referência aos diretórios `pcsx2/bios` e `pcsx2/resources`. |
| `OpenEmu/SystemPlugins/PlayStation 2/OEPS2SystemController.m` | Controlador do sistema PS2 já usado pela interface do OpenEmu. |
| `OpenEmu/SystemPlugins/PlayStation 2/PlayStation2-Info.plist` | Lista de controles DualShock 2, incluindo analógicos, botões, gatilhos, Start e Select. |
| `Scripts/build-armsx2-libretro-arm64.sh` | Compila ARMSX2/libretro e os shaders, cria e audita `ARMSX2.oecoreplugin`. |
| `Scripts/install-debug-armsx2-core.sh` | Instala no diretório de cores do usuário uma cópia do bundle Debug, confirma `arm64`, assina ad-hoc e limpa o log de diagnóstico. |
| `Scripts/audit-core-plugin-mach-o.sh` | Auditoria de arquitetura chamada pelo build e pelo instalador. |
| `ARMSX2_OPENEMU_INTEGRATION.md` | Resumo de status da integração. |
| `ARMSX2_WRAPPER_COMPATIBILITY.md` | Resumo de compatibilidade e próximos testes do wrapper. |

## Metadados do bundle e BIOS

O bundle produzido é `ARMSX2.oecoreplugin`. Sua estrutura relevante é:

```text
ARMSX2.oecoreplugin/
  Contents/
    Info.plist
    MacOS/ARMSX2
    Resources/
      armsx2_libretro.dylib
      GameIndex.yaml                 (quando presente na árvore compilada)
      resources/default.metallib
      resources/Metal22.metallib
      resources/Metal23.metallib
```

O `Info.plist` do core declara o sistema `openemu.system.ps2`, dois jogadores
e BIOS PS2 conhecidas pelo OpenEmu. Entre as entradas declaradas estão
`scph10000.bin`, `scph39001.bin` e `scph70004.bin`; o usuário deve utilizar
apenas dumps de BIOS que possua legalmente.

Em tempo de execução, `ARMSX2GameCore` recebe de `OEGameCore` um diretório de
suporte e prepara:

```text
<supportDirectoryPath>/
  system/pcsx2/
    bios/
    resources/
  saves/
```

No primeiro carregamento — e sempre que o conteúdo for diferente — o wrapper
copia `GameIndex.yaml`, `default.metallib`, `Metal22.metallib` e
`Metal23.metallib` do bundle para `system/pcsx2/resources/`. Isso é essencial:
o ARMSX2 procura recursos persistentes nessa estrutura, não somente dentro do
bundle do core.

## Build nativo arm64

### Pré-requisitos

- macOS em Apple Silicon;
- Xcode completo, incluindo `metal` e `metallib`;
- CMake, `pkg-config` e Homebrew;
- pacotes Homebrew: `libpng`, `jpeg-turbo`, `zstd`, `lz4`, `webp`, `sdl3`,
  `freetype`, `plutovg` e `plutosvg`;
- `OpenEmuBase.framework` previamente construído em uma pasta de produtos
  Debug do Xcode.

O script verifica as dependências via `pkg-config`. Quando `xcode-select`
aponta apenas para Command Line Tools e o compilador Metal não está disponível,
ele procura automaticamente `Xcode.app/Contents/Developer` ou
`Xcode-beta.app/Contents/Developer` e define `DEVELOPER_DIR` para a instalação
completa.

### Comando de build

Na raiz do repositório:

```sh
Scripts/build-armsx2-libretro-arm64.sh
```

Se o framework não estiver no Derived Data habitual, informe-o explicitamente:

```sh
OPENEMU_BASE_FRAMEWORK=/caminho/OpenEmuBase.framework \
Scripts/build-armsx2-libretro-arm64.sh
```

O script usa, por padrão:

```text
ARMSX2_ROOT = <raiz-do-repositório>/ARMSX2-Core
BUILD_DIR   = /tmp/openemu-armsx2-libretro-build
PRODUCTS    = /tmp/OpenEmu-Shared-DD/Build/Products/Debug
```

Esses valores podem ser substituídos pelas variáveis `ARMSX2_ROOT`,
`ARMSX2_BUILD_DIR` e `DERIVED_DATA`.

### O que o build faz

1. Configura CMake com `CMAKE_OSX_ARCHITECTURES=arm64`,
   `ENABLE_LIBRETRO=ON` e `USE_VULKAN=OFF`.
2. Compila o alvo `armsx2_libretro`.
3. Compila os oito arquivos `.metal` do ARMSX2 três vezes, para Metal 2.0,
   2.2 e 2.3, gerando `default.metallib`, `Metal22.metallib` e
   `Metal23.metallib`.
4. Compila `ARMSX2GameCore.mm` como biblioteca dinâmica `arm64`, vinculada a
   `Cocoa`, `Metal` e `OpenEmuBase`.
5. Copia o wrapper, a dylib, `Info.plist`, os metallibs e, quando disponível,
   `GameIndex.yaml` para `ARMSX2.oecoreplugin`.
6. Assina o bundle ad-hoc e executa a auditoria Mach-O.

Não reutilize bibliotecas Metal antigas de PCSX2 como solução normal. O script
tem um fallback apenas para a ausência temporária do compilador Metal; a rota
recomendada é sempre compilar os shaders da fonte ARMSX2 correspondente.

## Instalação do core Debug

Depois do build:

```sh
Scripts/install-debug-armsx2-core.sh \
  /tmp/OpenEmu-Shared-DD/Build/Products/Debug/ARMSX2.oecoreplugin
```

Sem argumento, o instalador procura o bundle Debug mais recente no Derived
Data. O destino é:

```text
~/Library/Application Support/OpenEmu/Cores/ARMSX2.oecoreplugin
```

O instalador confirma que `Contents/MacOS/ARMSX2` contém `arm64`, substitui
somente o bundle ARMSX2, assina-o ad-hoc, executa a auditoria e zera o arquivo
de diagnóstico `/tmp/openemu-armsx2-metal.log` para a próxima sessão.

Evite copiar manualmente plugins entre produtos Debug e Release ou assinar o
aplicativo inteiro com `codesign --deep` como método de correção. Esses passos
podem misturar binários, frameworks e assinaturas de produtos diferentes e
produzir falhas difíceis de diagnosticar.

## Ponte OpenEmu ↔ libretro ↔ Metal

### Wrapper libretro

`ARMSX2GameCore.mm` resolve e utiliza os seguintes grupos de símbolos:

- ciclo do core: `retro_init`, `retro_deinit`, `retro_load_game`,
  `retro_unload_game`, `retro_run` e `retro_reset`;
- AV: `retro_get_system_av_info`, `retro_set_video_refresh`,
  `retro_set_audio_sample` e `retro_set_audio_sample_batch`;
- input: `retro_set_input_poll`, `retro_set_input_state` e
  `retro_set_controller_port_device`;
- estados: `retro_serialize_size`, `retro_serialize` e
  `retro_unserialize`;
- extensão OpenEmu: `armsx2_openemu_set_metal_callbacks`.

O áudio é escrito no `OERingBuffer` do OpenEmu. O wrapper declara
explicitamente duas portas `RETRO_DEVICE_JOYPAD`; seus botões e eixos são
mapeados para os controles do `OEPS2SystemResponderClient`, incluindo os dois
stacks analógicos.

### Callbacks Metal adicionados

O wrapper registra as seguintes funções C na dylib:

| Exportação/Callback | Função |
|---|---|
| `armsx2_openemu_set_metal_callbacks` | Registra o contexto e os quatro callbacks do wrapper. |
| `armsx2_openemu_get_metal_device` | Fornece o `MTLDevice` do OpenEmu. |
| `armsx2_openemu_get_metal_texture` | Fornece a `MTLTexture` de destino do OpenEmu. |
| `armsx2_openemu_will_execute_metal` | Notifica o delegado de renderização antes do command buffer. |
| `armsx2_openemu_did_execute_metal` | Atualiza a leitura de diagnóstico e notifica o delegado após o command buffer. |
| `armsx2_openemu_mark_metal_presented` | Marca que houve apresentação Metal direta válida. |

`GSDeviceMTL.mm` usa o dispositivo fornecido pelo OpenEmu durante a criação e,
na apresentação, desenha diretamente na textura destino. Após a primeira
apresentação direta, `pcsx2-libretro/Main.cpp` suprime o fallback de vídeo por
CPU. Antes dela, o fallback é deliberadamente controlado para não publicar um
quadro incorreto enquanto a textura Metal ainda não recebeu um desenho válido.

O wrapper também lê a textura para um buffer Metal apenas para diagnóstico
(contagem de pixels não pretos, média RGB, predominância vermelha e hash). A
leitura não é o caminho de apresentação normal.

### Compatibilidade de shaders

As bibliotecas compiladas a partir da fonte ARMSX2 corrigiram a divergência de
constantes de função que aparecia com bibliotecas antigas, incluindo a falha
associada a `ROV_NEEDS_R32` e `Bool` versus `UInt`. Essa incompatibilidade
impedia a criação de `ps_main` e resultava em tela vermelha sólida ou ausência
de imagem/áudio em God of War.

Os logs `Shader fallback loaded` para conversões `depth*`/`float*` podem
ocorrer quando uma função específica não está presente na biblioteca Metal 2.3.
Quando o fallback correspondente carrega e os pipelines de conversão,
apresentação e merge são inicializados, essas mensagens isoladas não indicam
falha de boot.

## Ciclo de vida e robustez

1. `loadFileAtPath:error:` carrega a dylib, define callbacks, prepara
   diretórios, inicializa o core e carrega a ISO/CHD.
2. O libretro inicia a thread de CPU e `VMManager::Initialize`; o GS abre em
   Metal e os subsistemas PS2, incluindo SPU2, são inicializados.
3. O wrapper atualiza tamanho, proporção, taxa de quadros e taxa de amostragem
   com `retro_get_system_av_info`.
4. Ao encerrar ou falhar o boot, `stopEmulation` remove primeiro os callbacks
   Metal, descarrega o jogo, desinicializa a dylib e somente então faz
   `dlclose`.

Remover os callbacks antes de descarregar a biblioteca é necessário para que
um callback tardio do GS não aponte para um wrapper já destruído. Tentativas de
boot que falham também chamam o encerramento completo, em vez de deixar uma VM
parcialmente inicializada.

## Diagnóstico

### Arquivo de log principal

```text
/tmp/openemu-armsx2-metal.log
```

O wrapper grava nesse arquivo as mensagens `ARMSX2`, e a ponte libretro/Metal
complementa o rastreio de inicialização, apresentação e leitura da textura.

Para acompanhar em tempo real:

```sh
tail -f /tmp/openemu-armsx2-metal.log
```

Para uma captura curta após reproduzir um problema:

```sh
tail -250 /tmp/openemu-armsx2-metal.log
```

### Linhas que confirmam um boot saudável

Os nomes podem variar, mas o conjunto esperado inclui:

```text
[ARMSX2-libretro] CPUThreadInitialize succeeded
[ARMSX2-VMManager] Initialize returning StartupSuccess
[ARMSX2-GSDeviceMTL] Create returning true
[ARMSX2-GSDeviceMTL] OpenEmu present completed ... draws=1
[ARMSX2-libretro] Direct Metal present marked
```

Após o conteúdo real começar, as leituras Metal deixam de reportar somente
preto e passam a ter `nonBlack` e hash variáveis. Uma cor média avermelhada em
uma cena de God of War não é, por si só, a antiga tela vermelha: é preciso
verificar também que há composição dinâmica, `draws=1` e áudio.

### Problemas já identificados

| Sintoma | Diagnóstico / ação |
|---|---|
| `armsx2_libretro.dylib was not found` | Confirme `Contents/Resources/armsx2_libretro.dylib` no bundle e rode o build antes da instalação. |
| `Failed to load shader ps_main` ou tela vermelha persistente | Recompile os `.metallib` da fonte ARMSX2 com Xcode completo; não use bibliotecas antigas incompatíveis. |
| Primeiros frames pretos | Normal durante a inicialização do GS antes da primeira apresentação direta. |
| Flash rosa breve no carregamento | Conhecido como transição de superfície antes do primeiro quadro real; não é bloqueador se vídeo e áudio seguem normais. |
| Sem áudio junto com falha de vídeo | Verifique primeiro os pipelines Metal; em God of War a correção do shader restaurou os dois. |
| Jogo não inicia | Confirme ISO/CHD, BIOS legal instalada e o conteúdo de `system/pcsx2/resources`. |
| Core lento em Debug | Esperado enquanto o fluxo ainda é experimental; medir em Release só depois de produzir um produto consistente com seus plugins e frameworks. |

## Validação e pendências

### Validado

- bundle e dylib `arm64` construídos, auditados e instalados;
- boot de BIOS e ISO;
- inicialização de GS/Metal, SPU2, input e subsistemas principais;
- vídeo Metal direto e áudio em **God of War** (`SCUS-97399`);
- GameDB aplicado para `SCUS-97399`, com `autoFlush=1` e
  `halfPixelOffset=5`;
- atualização persistente de `GameIndex.yaml` e dos metallibs;
- encerramento que remove callbacks Metal antes da descarga;
- dois controles DualShock 2 declarados explicitamente.

### Ainda pendente

- regressão completa de **Gran Turismo 4**: tela inicial, menus, HUD, corrida
  e composição de múltiplas camadas;
- desempenho fora de Debug;
- input em jogo, memory cards, save/load state e ciclos repetidos de abertura;
- estabilidade prolongada em títulos distintos;
- eliminar o flash rosa somente se ele passar a ocorrer durante o jogo ou
  mascarar uma falha funcional.

## Checklist de regressão antes de distribuir

1. Fazer build novo com `Scripts/build-armsx2-libretro-arm64.sh`.
2. Rodar a auditoria Mach-O do bundle produzido e confirmar que wrapper e dylib
   são `arm64`.
3. Instalar somente com `Scripts/install-debug-armsx2-core.sh`.
4. Abrir a mesma variante do OpenEmu para a qual o bundle foi produzido;
   não misturar produtos Debug e Release.
5. Validar God of War por ao menos uma sessão de jogo com vídeo, áudio,
   controle e encerramento.
6. Validar Gran Turismo 4 até uma corrida e voltar ao menu.
7. Testar criação/carregamento de memory card e save state.
8. Fechar e reabrir o jogo diversas vezes; confirmar ausência de crash e de
   callbacks tardios no log.

## Referências internas

- [Resumo da integração](ARMSX2_OPENEMU_INTEGRATION.md)
- [Compatibilidade do wrapper](ARMSX2_WRAPPER_COMPATIBILITY.md)
- [Status geral do projeto](PROJECT_STATUS.md)
- [Status de refatoração da árvore ARMSX2](ARMSX2-Core/REFACTOR_STATUS.md)
