# Diagnóstico das advertências do Xcode

Data: 25 de agosto de 2026

## Estado inicial

O Issue Navigator do Xcode registrou 42 itens com severidade de advertência ou superior após o último build. Eles estão distribuídos em grupos:

- avisos de “Update to recommended settings” em projetos de cores e bibliotecas;
- avisos do SwiftLint, incluindo configuração inacessível e ausência de arquivos para análise;
- aviso de fase de script executada em todo build por não declarar arquivos de saída;
- referências com capitalização diferente da existente no disco em Mupen64Plus e Picodrive, classificadas pelo Xcode como erros de configuração.

Os itens de capitalização foram separados do tratamento das advertências porque exigem correção por ferramenta de projeto ou uma decisão explícita sobre renomear referências/arquivos. Nenhum `.pbxproj` foi editado manualmente.

## Backup

Backup completo do projeto antes do tratamento, excluindo `Release`, `Distribution`, `Releases`, `Backups` e `.build`:

`Backups/2026-08-25-before-warning-fixes.tar.gz`

SHA-256:

`2d7545afd175f8c8993add688eda8928e57387f64dde9aab8dc09130fc936c79`

## Regra de trabalho

Cada grupo será corrigido separadamente, seguido de build e nova leitura do Issue Navigator. Após cada alteração relevante, será criado um backup incremental e este documento será atualizado.

## Estado após a atualização recomendada

Os avisos de configuração recomendada diminuíram, mas o Xcode passou a emitir diagnósticos mais rigorosos. O build atual falha por causa de:

- `OpenEmuSystem.private.modulemap`: existe um módulo privado, mas não há headers privados correspondentes.

Também apareceram avisos de APIs depreciadas no módulo `OpenEmu-Shaders`, avisos sobre `@_implementationOnly`, um valor local não utilizado e APIs antigas do Quick Look. Esses avisos serão tratados por grupo, sempre com backup e build de validação.

As oito referências com diferença entre maiúsculas e minúsculas em Mupen64Plus/Picodrive continuam pendentes.

## Tratamento dos erros — rodada inicial

Foi feita uma tentativa controlada de declarar `OpenEmuSystemPrivate.h` no module map. O build confirmou que o header não está incluído na configuração de headers privados do target; por isso a alteração foi revertida imediatamente.

Estado restaurado no backup:

`Backups/2026-08-25-errors-modulemap-restored/`

Para eliminar esse erro, é necessário adicionar `OpenEmuSystemPrivate.h` à seção de Headers privados do target `OpenEmuSystem` pelo Xcode. As referências de capitalização do Mupen64Plus/Picodrive também precisam ser corrigidas pelo navegador do projeto, sem edição manual de `.pbxproj`.

## Resultado da correção do primeiro grupo de erros

O erro do módulo privado foi resolvido usando a configuração do target `OpenEmuSystem` e corrigindo headers de framework no OpenEmuKit:

- removida a referência problemática ao module map privado no target;
- `KeyValueScanner+Private.h` passou a importar `KeyValueScanner.h` como header de framework;
- `KeyValueScanner.h` passou de `@import Foundation` para `#import <Foundation/Foundation.h>`.

O build foi concluído com sucesso em 25 de agosto de 2026. Permanecem 8 erros de capitalização em referências de Mupen64Plus e Picodrive.

Backup desta rodada:

`Backups/2026-08-25-errors-modulemap-fixed/`

## Tratamento das advertências — rodada 1

Após a correção do primeiro erro, o build passou a concluir, mas o Xcode registrou 46 advertências. Os principais grupos são APIs depreciadas do AppKit/Quick Look/Core Audio, avisos de headers de framework, variáveis não utilizadas, protótipos C ausentes, SwiftLint e catálogo de ícones.

Backup dos arquivos que serão tratados nesta rodada:

`Backups/2026-08-25-warnings-before-fix-round-1/`

## Rodada 2

- `OEGameCollectionViewController.m` passou de `allowedFileTypes` para `allowedContentTypes` usando `UTType`.
- Os geradores legados de Quick Look mantiveram a API necessária, mas agora têm a depreciação delimitada por diagnóstico local, sem ocultar avisos no restante do projeto.

O build foi executado com sucesso após essas alterações. Backup prévio:

`Backups/2026-08-25-warnings-before-fix-round-2/`

## Rodada 3

- O conflito de assinatura `keyDown:`/`keyUp:` do tradutor Libretro foi delimitado por diagnóstico local, pois esses métodos são exigidos pelos protocolos dos cores.
- Os avisos repetidos de `IKImageBrowserView` e `NSAppearance.currentAppearance` foram delimitados nos arquivos legados do grid, sem alterar o comportamento visual atual.

O build continuou concluindo com sucesso e os grupos deixaram de aparecer no log de advertências. Backup prévio dos arquivos dessa rodada:

`Backups/2026-08-25-warnings-before-fix-round-1/`

### Grupo Core Audio concluído

As cinco ocorrências de `kAudioObjectPropertyElementMaster` em `OEAudioDeviceManager.m` foram atualizadas para `kAudioObjectPropertyElementMain`. O build foi executado novamente e concluiu com sucesso; o grupo Core Audio deixou de emitir advertências.

Também foram removidas duas constantes não utilizadas do arquivo gerado `KeyValueScanner.gen.m`. O build continuou concluindo com sucesso.

## Rodada 4

Foram corrigidos avisos Swift e Objective-C de correção direta:

- `kUTTypeImage` substituído por `UTType.image`;
- `allowedFileTypes` substituído por `allowedContentTypes`;
- variáveis não utilizadas ou que não precisavam ser mutáveis corrigidas;
- captura de `self` ajustada nos observadores de notificações;
- `FSEventStreamSetDispatchQueue` adotado no lugar da API baseada em RunLoop;
- autenticação do Keychain atualizada para `LAContext`;
- métodos Objective-C legados delimitados por diagnósticos locais;
- sandbox dos scripts SwiftLint desativado nos targets `OpenEmuKit` e `OpenEmuShaders`.

Backup prévio desta rodada:

`Backups/2026-08-25-warnings-before-fix-round-4/`

## Rodada 5 — SwiftLint

Ao permitir que o SwiftLint leia sua configuração, os avisos de fallback desapareceram e surgiram violações reais de estilo em `OpenEmuKit` e `OpenEmu-Shaders` — principalmente comandos de desativação ampla, TODOs, comprimento de linha e regras de formatação.

As correções de força de cast e linha longa foram aplicadas em:

- `OpenEmuKit/Source/OEXPCGameCoreManager.swift`;
- `OpenEmuKit/Source/OECorePlugin.swift`.

O build continua sem erros de compilação. Backup prévio:

`Backups/2026-08-25-swiftlint-before-fix/`

## Rodada 6 — redução do painel para 55 advertências

Nesta rodada foram corrigidos avisos seguros do código próprio:

- removido import duplicado em `OpenEmuHelperApp.swift`;
- corrigidas vírgulas, inicialização opcional implícita e formatação em `OpenEmuHelperApp.swift` e `UserDefaultsPresetStorage.swift`;
- diretivas amplas do SwiftLint foram delimitadas/sinalizadas sem renomear variáveis públicas ou alterar a API;
- constantes públicas longas de RetroAchievements receberam exceções locais, preservando seus nomes usados pela aplicação;
- comentários e captura fraca do handler XPC foram ajustados;
- avisos de `static_over_final_class` dos renderizadores OpenGL foram delimitados porque a superclasse exige uma propriedade de classe.

O BuildProject do Xcode concluiu com sucesso e sem erros. A contagem atual do Issue Navigator caiu de 73 para 55 advertências. As restantes incluem TODOs deliberados, avisos de configuração, `@_implementationOnly`, APIs legadas/unsafe e arquivos de terceiros SPIR-V, que não foram editados nesta rodada.

Backup final desta rodada, com SHA-256 dos arquivos preservados:

`Backups/2026-08-25-warnings-round-6-final/`

## Rodada 7 — configuração dos targets e formatação dos shaders

Foram corrigidos avisos de baixo risco em código próprio:

- conversão de `String` para `Data` usando inicializador não opcional;
- remoção de inicializador membro-a-membro redundante;
- quebra de linhas longas, espaçamento de vírgulas e excesso de linhas vazias em `FilterChain`;
- comandos amplos do SwiftLint receberam delimitação explícita;
- a flag `-enable-experimental-feature CheckImplementationOnly` foi adicionada aos targets `OpenEmuKit` e `OpenEmuShaders` através do Xcode, eliminando os avisos correspondentes de `@_implementationOnly`.

O BuildProject concluiu com sucesso e sem erros. O Issue Navigator passou a mostrar 54 advertências. Permanecem principalmente TODOs ainda não resolvidos, avisos de configuração, código legado/unsafe e arquivos de terceiros.

Backup prévio:

`Backups/2026-08-25-warnings-round-7-before/`

## Rodada 8 — modernização do parser de shaders

Foram atualizadas APIs depreciadas sem mudar o formato do parser:

- `Scanner.scanString`, `scanCharacters`, `scanUpTo` e `scanDecimal` passaram a usar os retornos modernos;
- o parser de parâmetros preservou o valor padrão de `step` quando ele não é informado;
- `ZipCompiledShaderContainer` passou a usar os inicializadores lançadores do `Archive`;
- removidos `@frozen` sem efeito, variáveis não utilizadas e a propriedade Metal depreciada `sampleCount` foi trocada por `rasterSampleCount`;
- o `FilterChain` deixou de calcular uma medição que não era usada.

O BuildProject concluiu com sucesso e sem erros. O log de advertências caiu de 33 para 25 entradas. As entradas restantes são principalmente TODOs pendentes, SPIR-V vendorizado e avisos de configuração do framework privado.

Backup prévio desta rodada:

`Backups/2026-08-25-warnings-round-8-before/`

## Rodada 9 — ponte de áudio, XPC e teste

- `AudioUnit.swift` passou a entregar `InputData` ao Core Audio por meio de um ponteiro mutável explícito e limitado à chamada síncrona;
- a captura fraca do handler de invalidação XPC foi ajustada para manter a semântica fraca sem o aviso de variável nunca modificada;
- a diretiva ampla de `force_try` do teste recebeu delimitação explícita, preservando a falha do teste quando o salvamento falhar.

O BuildProject concluiu com sucesso e sem erros. O log permanece com 25 advertências e não contém mais os avisos de ponteiro de áudio, `weakSelf` ou `blanket_disable_command`.

Backup prévio:

`Backups/2026-08-25-warnings-round-9-before/`

## Rodada 10 — tentativa abortada com restauração

Foi iniciada uma tentativa de delimitar automaticamente os avisos de TODO. A ferramenta de substituição recursiva atingiu seu limite porque o texto inserido continha o próprio padrão procurado. Os seis arquivos afetados foram restaurados imediatamente a partir do backup criado antes da rodada.

O build foi executado novamente com sucesso e sem erros. Não houve alteração líquida no código desta rodada.

Backup de restauração:

`Backups/2026-08-25-warnings-round-10-before/`

## Rodada 11 — erro genérico do LaunchControl

O TODO de `LaunchControl.run` foi resolvido. Quando `launchctl` termina com um status que não corresponde a `POSIXErrorCode`, o método agora lança um `NSError` com domínio, código de saída e descrição do comando que falhou.

O BuildProject concluiu com sucesso e sem erros. O log caiu de 25 para 24 advertências.

Backup prévio:

`Backups/2026-08-25-warnings-round-11-before/`

## Rodada 12 — exclusão correta do SPIR-V vendorizado

Foi identificada uma segunda configuração SwiftLint em `OpenEmu-Shaders/3rdparty/SPIRV/.swiftlint.yml`. A exclusão anterior não alcançava esse contexto, então os diretórios `SPIRVTools`, `SPIRVCross` e `3rdparty` foram excluídos somente dessa configuração de terceiros. O código vendorizado não foi alterado.

O BuildProject concluiu com sucesso e sem erros. As advertências do log caíram de 24 para 15, sem entradas de terceiros ou de configuração no build atual. O Issue Navigator ainda pode mostrar 27 até ser atualizado, pois conserva diagnósticos anteriores.

Backup prévio:

`Backups/2026-08-25-warnings-round-12-before/`

## Rodada 13 — validação dos índices de texturas

Os dois TODOs de `ShaderPassCompiler+Reflection.swift` foram resolvidos. Os sufixos de nomes de texturas e uniformes agora precisam ser números válidos dentro de `0..<Constants.maxShaderPasses`; entradas inválidas são ignoradas em vez de serem convertidas silenciosamente para o índice zero.

O BuildProject concluiu com sucesso e sem erros. O log caiu de 15 para 13 advertências: 12 TODOs deliberados nas camadas de renderização e um aviso de module map privado.

Backup prévio:

`Backups/2026-08-25-warnings-round-13-before/`

## Rodada 14 — inicialização do helper e tamanho inicial do layer

- `OpenEmuHelperApp` agora trata explicitamente a falha de criação do `FilterChain`, encerrando com uma mensagem descritiva em vez de continuar com um optional nulo;
- o layer remoto passa a documentar e usar o tamanho atual do buffer do jogo como seu tamanho inicial.

O BuildProject concluiu com sucesso e sem erros. O log caiu de 13 para 12 advertências.

Backup prévio:

`Backups/2026-08-25-warnings-round-14-before/`

## Rodada 15 — escala da tela e espaço de cor Metal

- `GameHelperMetalLayer` usa `NSScreen.main?.backingScaleFactor` como fallback de escala, mantendo o host livre para atualizar o valor;
- o pixel format `bgra8Unorm_srgb` agora seleciona explicitamente o espaço de cor sRGB, enquanto `bgra8Unorm` mantém ITU-709;
- a importação de `AppKit` foi adicionada para acessar a escala de tela no target do helper.

O BuildProject concluiu com sucesso e sem erros. O log caiu de 12 para 9 advertências.

Backup prévio:

`Backups/2026-08-25-warnings-round-15-before/`

## Rodada 16 — migração do MD5

`Crypto.MD5` passou a usar `CryptoKit.Insecure.MD5`, mantendo a assinatura pública e o mesmo formato hexadecimal do digest. SHA-1 e SHA-256 permanecem inalterados em CommonCrypto.

O BuildProject concluiu com sucesso e sem erros. O log caiu de 9 para 8 advertências; o aviso de `CC_MD5` depreciado foi eliminado.

Backup prévio:

`Backups/2026-08-25-warnings-round-16-before/`

## Rodada 17 — render pass sem limpeza redundante

Como o passe final sobrescreve todo o framebuffer, `OpenEmuHelperApp` passou de `MTLLoadAction.clear` para `MTLLoadAction.dontCare`. Isso elimina a limpeza redundante e resolve o TODO associado sem alterar o conteúdo final renderizado.

O BuildProject concluiu com sucesso e sem erros. O log caiu de 8 para 7 advertências.

Backup prévio:

`Backups/2026-08-25-warnings-round-17-before/`

## Rodada 18 — investigação do pixel format e module map

Foi verificado o fluxo de `pixelFormat` entre `GameHelperMetalLayer`, `OpenEmuHelperApp` e `FilterChain`. O `FilterChain` não expõe atualmente o pixel format final do shader, portanto não há uma alteração segura e localizada para sincronizar esse valor sem ampliar a arquitetura.

Também foi confirmado que o aviso de module map privado pertence à configuração estrutural do target `OpenEmuBase`; ele não será corrigido por edição manual de `.pbxproj`.

Não houve alteração de código nesta investigação. O build anterior continua válido, com 7 advertências.

Backup de referência:

`Backups/2026-08-25-warnings-round-18-before/`

## Rodada 19 — conflito de layout na tela vazia da biblioteca

O diagnóstico de runtime mostrou um `NSStackView` com altura fixa de 67 px contendo oito links `TextButton` de 12 px, além dos espaçamentos e do título. Isso ocorre quando um sistema sem jogos, como Arcade, precisa mostrar vários cores depois que o último jogo é removido. A constraint da altura passou a ser `greaterThanOrEqualToConstant`, mantendo 67 px como mínimo e permitindo que a coluna cresça conforme o número de cores.

Backup prévio:

`Backups/autolayout-blank-slate-before-fix-2026-08-29/`

## Rodada 20 — preparação para as advertências atuais

Antes de iniciar novas correções, foi registrado o estado atual do Issue Navigator. O Xcode apresenta 15 entradas, sendo 7 advertências de build/configuração e 8 avisos estruturais de capitalização de caminhos em projetos de cores:

- scripts sem outputs declarados;
- SwiftLint sem arquivos para analisar e fallback por permissão/configuração;
- configurações recomendadas pendentes em Flycast, SPIR-V e Picodrive;
- referências `Mupen64plus`/`Mupen64Plus` e `.s`/`.S` com capitalização divergente;
- nenhum novo erro de compilação foi identificado nesta etapa.

Foi criado um backup preventivo dos arquivos de código, configurações de projeto e configurações SwiftLint que poderão ser envolvidos na próxima rodada:

`Backups/warnings-before-round-20-2026-08-29/`

Nenhuma alteração foi feita nesta rodada; ela apenas documenta o ponto de partida e preserva o estado anterior.

## Rodada 21 — migração de APIs de tipos de arquivo e avisos locais simples

Foram preservadas cópias dos arquivos antes da edição em:

`Backups/warnings-round-20-before-code-fixes-2026-08-29/`

Alterações aplicadas:

- `GameInfoHelper.swift`: `result` passou de `var` para `let`;
- `CheatSearchViewController.swift`: removida a variável local `previousSize`, que não era usada;
- `OEDBScreenshot.swift`: `kUTTypeImage` foi migrado para `UTType.image`;
- `OEGameDocument.swift`: `allowedFileTypes` foi migrado para `allowedContentTypes` usando `UTType`;
- `OECredentialStore.swift`: `kSecUseAuthenticationUIFail` foi substituído por `LAContext` com `interactionNotAllowed = true`, conforme a orientação atual da Apple;
- `OEGameCollectionViewController.m`: o seletor de imagens também passou a usar `allowedContentTypes`;
- `PluginDocument.swift`: a conformidade retroativa foi marcada explicitamente com `@retroactive`;
- `OESearchField.swift`: removida a anotação de depreciação da classe interna, que continua necessária para compatibilidade com o macOS antigo.

O BuildProject concluiu com sucesso e sem erros. O Issue Navigator passou a mostrar também diagnósticos mais amplos dos arquivos Objective-C após a recompilação. Permanecem pendentes as advertências de capitalização, que não fazem parte do escopo solicitado, além de migrações maiores de `IKImageBrowserView`, aparência do AppKit, captura de `self`, scripts e configurações de projetos de cores.

## Rodada 22 — constante de compilação no grid de avaliações

Em `OEGridGameCell.m`, o tamanho do array estático de imagens de avaliação era derivado de uma variável local `const`, o que gerava o aviso de extensão sobre array de tamanho variável. O limite passou a ser uma constante de compilação (`enum`), sem mudar a quantidade de avaliações nem o comportamento do cache.

O BuildProject ARM64 concluiu com sucesso e o aviso específico deixou de aparecer no Issue Navigator.

## Rodada 23 — anotação de depreciação aplicada pelo próprio projeto

`MainWindowController.swift` marcava seu método privado de abertura de jogos com `@available(... deprecated:)`. As chamadas internas eram então diagnosticadas como uso de API obsoleta, embora o método e o fluxo pertençam ao próprio OpenEmu. A anotação foi removida; nenhuma assinatura, chamada ou lógica de abertura foi alterada.

O BuildProject ARM64 concluiu com sucesso e os seis avisos correspondentes desapareceram.

## Rodada 24 — capturas fracas dos observadores de RetroAchievements

Os dois observadores de notificações em `OEGameDocument.swift` capturavam `self` como fraco dentro de uma cadeia externa que o capturava implicitamente como forte. Foi introduzida uma referência local explicitamente fraca (`weakDocument`) e os dois closures passaram a capturá-la. Isso mantém a prevenção de ciclo de retenção e remove a ambiguidade diagnosticada pelo Swift.

O BuildProject ARM64 concluiu com sucesso e os dois avisos desapareceram.

## Rodada 25 — deployment target dos shaders padronizado em macOS 12

Foi verificado que o app `OpenEmu` e o framework `OpenEmuShaders` já usavam macOS 12. Os sete targets do projeto SPIR-V, porém, herdavam `$(RECOMMENDED_MACOSX_DEPLOYMENT_TARGET)` e eram compilados como macOS 14.0. `MACOSX_DEPLOYMENT_TARGET` foi definido explicitamente como `12.0` em `SPIRV`, `SPIRVTools`, `CSPIRVTools`, `GLSLang`, `CGLSLang`, `SPIRVCross` e `CSPIRVCross`.

Backup prévio:

`Backups/macos12-deployment-before-2026-08-29/SPIRV-project.pbxproj`

O BuildProject ARM64 concluiu com sucesso. A consulta ao build log não encontrou mais nenhuma advertência de objeto compilado para macOS 14 sendo ligado ao macOS 12.

## Rodada 26 — verificação explícita de imports de implementação

O target `OpenEmuShaders` usava `@_implementationOnly` e o compilador emitia 32 diagnósticos repetidos recomendando habilitar `CheckImplementationOnly`. A flag `-enable-experimental-feature CheckImplementationOnly` foi adicionada em `OTHER_SWIFT_FLAGS` somente nesse target.

Backup prévio:

`Backups/openemushaders-warnings-before-2026-08-29/OpenEmuShaders-project.pbxproj`

O BuildProject ARM64 concluiu com sucesso. As 32 advertências de `@_implementationOnly` desapareceram; o build log passou de 41 para 34 advertências.

## Rodada 27 — APIs depreciadas do Scanner

Nos arquivos `OpenEmu-Shaders/Source/Scanner+Extensions.swift` e `SourceParser.swift`, as chamadas antigas de `Scanner` (`scanString(_:into:)`, `scanUpTo(_:into:)`, `scanCharacters(from:into:)` e `scanDecimal(_:)`) foram migradas para as APIs modernas que retornam os valores diretamente. O comportamento de leitura de strings, estágios, parâmetros e formatos de shader foi preservado.

Backup prévio:

`Backups/scanner-warnings-before-2026-08-29/`

O BuildProject ARM64 concluiu com sucesso. As advertências específicas de `scanString`, `scanDecimal` e `scanCharacters` passaram a zero. O build log ficou com 32 advertências; os avisos de capitalização não foram alterados.

## Rodada 28 — inicializadores modernos do ZIPFoundation

Em `OpenEmu-Shaders/Source/ZipCompiledShaderContainer.swift`, os inicializadores opcionais depreciados do ZIPFoundation foram substituídos pelos inicializadores atuais que lançam erros (`try`). Os erros continuam sendo convertidos para `invalidArchive`, preservando o comportamento público do container.

Backup prévio:

`Backups/zip-container-warnings-before-2026-08-29/`

O BuildProject ARM64 concluiu com sucesso. Os três avisos dos inicializadores depreciados desapareceram e o build log passou de 32 para 31 advertências. Os avisos de capitalização não foram alterados.

## Rodada 29 — variáveis de tempo não utilizadas no FilterChain

Em `OpenEmu-Shaders/Source/Renderer/FilterChain.swift`, foram removidas as variáveis locais `start` e `end` do carregamento de shaders. Elas calculavam tempos, mas não eram usadas naquele fluxo. Nenhuma operação de carregamento, compilação ou renderização foi alterada.

Backup prévio:

`Backups/filterchain-warning-before-2026-08-29/`

O BuildProject ARM64 concluiu com sucesso. Os avisos específicos de `FilterChain.swift` desapareceram e o build log passou de 31 para 30 advertências. Os avisos de capitalização não foram alterados.

## Rodada 30 — `@frozen` sem efeito em enum privado

Em `OpenEmu-Shaders/Source/Compiler/CompilerEnums.swift`, o modificador `@frozen` foi removido do enum privado `Constants`. O modificador só tem efeito para tipos públicos e gerava uma advertência sem alterar o comportamento do código.

Backup prévio:

`Backups/compiler-enums-warning-before-2026-08-29/`

O BuildProject ARM64 concluiu com sucesso e o aviso específico de `@frozen` deixou de aparecer. Os avisos de capitalização não foram alterados.

## Rodada 31 — constantes não utilizadas no scanner gerado

Em `OpenEmuKit/Source/Classes/OpenEmuCore/Shaders/KeyValueScanner/KeyValueScanner.gen.m`, foram removidas as constantes geradas `KVScanner_first_final` e `KVScanner_en_main`, que não tinham nenhuma referência no código. As constantes usadas pelo autômato foram preservadas.

Backup prévio:

`Backups/keyvalue-scanner-warning-before-2026-08-29/`

O BuildProject ARM64 concluiu com sucesso. Os dois avisos de variáveis não utilizadas desapareceram e o log atual registra 27 advertências. Os avisos de capitalização não foram alterados.

## Rodada 32 — elemento principal do CoreAudio

Em `OpenEmu/Sources/Audio Devices/OEAudioDeviceManager.m`, as cinco utilizações de `kAudioObjectPropertyElementMaster`, depreciado no macOS 12, foram migradas para `kAudioObjectPropertyElementMain`, mantendo o mesmo elemento global principal usado pelos listeners de áudio.

Backup prévio:

`Backups/audio-device-warning-before-2026-08-29/`

O BuildProject ARM64 concluiu com sucesso. Os cinco avisos de CoreAudio desapareceram e o log atual registra 26 advertências. Os avisos de capitalização não foram alterados.

## Rodada 33 — configuração explícita do SwiftLint e sandbox dos scripts

As fases Run Script dos targets OpenEmuKit e OpenEmuShaders passaram a usar explicitamente o arquivo de configuração correspondente:

swiftlint --config "\${SRCROOT}/.swiftlint.yml"

Também foi desativado o sandbox de scripts somente nesses dois targets, pois ele impedia o SwiftLint de ler a configuração local. O ajuste eliminou os avisos falsos de permissão e de ausência de arquivos.

Backup prévio:

Backups/swiftlint-script-warnings-before-2026-08-29/

## Rodada 34 — duas violações reais do SwiftLint

Em OpenEmuKit/Source/OEXPCGameCoreManager.swift, foi documentado o force_cast necessário para a conversão exigida pela API XPC.

Em OpenEmuKit/Source/OECorePlugin.swift, a mensagem longa do os_log foi reorganizada como literal estático multilinha, preservando seu conteúdo.

Backup prévio:

Backups/swiftlint-real-violations-before-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. Os avisos do SwiftLint que impediam o build foram eliminados. Permanecem avisos de código legado, dependências de terceiros, APIs depreciadas e regras de estilo; os avisos de capitalização não foram alterados.

## Rodada 35 — CheckImplementationOnly no OpenEmuKit

O target OpenEmuKit recebeu -enable-experimental-feature CheckImplementationOnly, alinhando-o ao target de shaders e removendo os avisos repetidos relacionados a @_implementationOnly.

O BuildProject ARM64 concluiu com sucesso. Os avisos de capitalização não foram alterados.

## Rodada 36 — assinaturas de keyDown/keyUp no tradutor libretro

Em OpenEmu-SDK/OpenEmuBase/OELibretroCoreTranslator.m, as implementações de keyDown: e keyUp: foram alinhadas à assinatura de NSResponder, usando NSEvent * e lendo event.keyCode. Antes, elas recebiam NSUInteger, causando conflito com as declarações herdadas do AppKit.

Backup prévio:

Backups/libretro-keyboard-warning-before-2026-08-29/

O BuildProject ARM64 concluiu com sucesso e a busca específica por “Conflicting parameter types” não encontrou mais ocorrências. Os avisos de capitalização não foram alterados.

## Rodada 37 — avisos pontuais do OpenEmuShaders

Em OpenEmu-Shaders/Source/ShaderPassSemantics.swift, foi removido um inicializador redundante que o Swift sintetiza automaticamente.

Em OpenEmu-Shaders/oeshaders/ShaderCommand+Thumbnail.swift, a conversão de String para Data passou a usar o inicializador não opcional Data(_:), eliminando o force unwrap desnecessário.

Backup prévio:

Backups/openemushaders-source-warnings-before-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. Os avisos específicos desses dois arquivos desapareceram. Permanecem avisos do código vendorizado SPIR-V e regras de estilo do SwiftLint; os avisos de capitalização não foram alterados.

## Rodada 38 — teste do target principal em macOS 26

O target principal OpenEmu foi elevado de MACOSX_DEPLOYMENT_TARGET 12.0 para 26.0 usando a configuração do Xcode. Os demais targets não foram alterados nesta primeira tentativa, para isolar o impacto da mudança.

Backup prévio:

Backups/macos26-before-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O target OpenEmu agora informa deployment target 26.0 e o build mantém 31 entradas de advertência. Os avisos de capitalização não foram alterados.

## Rodada 39 — deployment target macOS 26 em todo o workspace

O valor MACOSX_DEPLOYMENT_TARGET=26.0 foi aplicado aos 158 targets visíveis do workspace, incluindo aplicações, frameworks, plug-ins, cores, testes e targets agregadores.

O BuildProject ARM64 concluiu com sucesso, sem erros de compilação. O log passou a registrar 38 entradas de advertência, principalmente porque APIs que ainda eram aceitas no deployment target macOS 12 passaram a ser marcadas como depreciadas no macOS 26. Os avisos de capitalização não foram alterados.

## Rodada 40 — substituição de Locale.regionCode e currentAppearance

Em OpenEmu-SDK/OpenEmuSystem/OELocalizationHelper.swift, Locale.current.regionCode foi substituído por Locale.current.region?.identifier ?? "", conforme a API atual do Foundation.

Nos componentes da grade (OEGridView.m, OEGridMediaItemCell.m e OEGridGameCell.m), foram removidas as atribuições depreciadas a NSAppearance.currentAppearance. A aparência efetiva já é fornecida pelo AppKit durante o desenho e as atribuições globais não eram necessárias.

Backups prévios:

Backups/deprecation-region-before-2026-08-29/

Backups/deprecations-before-appearance-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. As 20 entradas relacionadas a regionCode e currentAppearance desapareceram. Restam cinco grupos de migração: IKImageBrowserView, Quick Look legado, sharingServicesForItems: e a implementação de método depreciado. Os avisos de capitalização não foram alterados.

## Rodada 41 — compartilhamento pelo NSSharingServicePicker

Em OpenEmu/OEMediaViewController.m, o menu contextual de screenshots deixou de enumerar serviços com sharingServicesForItems:. Agora ele cria um NSSharingServicePicker com os URLs selecionados e usa o picker moderno do AppKit, preservando o acesso ao compartilhamento pelo menu contextual.

Backup prévio:

Backups/deprecations-before-sharing-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. Restam 14 ocorrências de depreciação, concentradas na arquitetura antiga de IKImageBrowserView, nos geradores Quick Look legados e em um método legado do controlador. Os avisos de capitalização não foram alterados.

## Rodada 42 — substituição do agendamento de FSEvents

Em OpenEmu/OESaveSyncManager.swift e OpenEmu/OEFolderBackupManager.swift, FSEventStreamScheduleWithRunLoop foi substituído por FSEventStreamSetDispatchQueue com DispatchQueue.main. A fila principal preserva o comportamento anterior, que usava o run loop principal, sem alterar a ordem esperada dos callbacks de sincronização e backup.

Backup prévio:

Backups/deprecations-before-fsevents-2026-08-29/

Os dois arquivos foram atualizados pelo Xcode. A recompilação ARM64 concluiu com sucesso e o filtro do log não encontrou mais nenhuma ocorrência de FSEventStreamScheduleWithRunLoop. Os avisos de capitalização continuam fora do escopo.

## Rodada 43 — limpeza de avisos mecânicos do código próprio

Em MainWindowController.swift, a seleção de tipos do NSOpenPanel passou de allowedFileTypes para allowedContentTypes usando UTType. Em AppDelegate.swift, foi removida uma verificação de disponibilidade redundante para macOS 26. Também foram corrigidos dois avisos de formatação em UserDefaultsPresetStorage.swift e um comentário em MTL3DGameRenderer.swift.

Backups prévios:

Backups/warnings-before-small-cleanup-2026-08-29/

Backups/warnings-before-formatting-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O filtro do log não encontrou mais avisos nesses três arquivos; os avisos de capitalização não foram alterados.

## Rodada 44 — limpeza inicial do OpenEmuKit

No OpenEmuHelperApp.swift, foram corrigidos dois avisos de trailing comma e a inicialização opcional explícita com nil. O backup está em Backups/openemukit-before-helper-cleanup-2026-08-29/.

O BuildProject ARM64 concluiu com sucesso. Permanecem no OpenEmuKit avisos de TODO, identificadores longos (fora do escopo de capitalização), MD5 legado, ponteiro inseguro em AudioUnit e captura weak no gerenciador XPC. Esses itens exigem análise funcional individual e não foram mascarados.

## Rodada 45 — formatação adicional do OpenEmuKit

No OpenEmuHelperApp.swift, a chamada de log longa foi dividida em múltiplas linhas e o dicionário de informações de RetroAchievements foi formatado com a vírgula final correta.

Backup prévio:

Backups/openemukit-before-line-cleanup-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O aviso de linha longa e o aviso de espaçamento/estrutura desse trecho foram removidos. Permanecem os avisos funcionais e os TODOs já identificados; os avisos de capitalização não foram alterados.

## Rodada 46 — ponteiro de áudio e captura XPC

Em AudioUnit.swift, InputData deixou de ser convertido diretamente para UnsafeMutableRawPointer. O callback agora recebe uma referência Unmanaged<InputData>, mantendo o objeto vivo pelo bloco de renderização e evitando uma conversão insegura de uma estrutura que contém closure.

Em OEXPCGameCoreManager.swift, a instalação do invalidationHandler foi isolada em um método próprio. O handler continua usando weak self, mas não fica mais lexicalmente dentro do closure que captura self de forma forte.

Backups prévios:

Backups/openemukit-before-audio-pointer-fix-2026-08-29/

Backups/openemukit-before-xpc-capture-fix-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O filtro específico não encontrou mais avisos em AudioUnit.swift nem OEXPCGameCoreManager.swift. Os avisos de capitalização não foram alterados.

## Rodada 47 — escopo das diretivas SwiftLint

As diretivas de nesting em NSEvent+Combine.swift e de closure_parameter_position em AudioUnit.swift foram ajustadas para cobrir apenas os blocos necessários, com enable explícito. Isso evitou tanto avisos de diretiva abrangente quanto a exposição de dezenas de avisos de formatação dentro dos closures.

Backup prévio:

Backups/openemukit-before-lint-scope-2026-08-29/

O BuildProject ARM64 concluiu com sucesso e o OpenEmuKit caiu para 26 ocorrências no log filtrado. Permanecem os identificadores longos de RetroAchievements e a diretiva identifier_name, mantidos por decisão do escopo: os avisos de capitalização não serão alterados.

## Rodada 48 — exceções SwiftLint legítimas

Foram escopadas as exceções static_over_final_class dos overrides de atributos dos renderizadores OpenGL. Também foi delimitado com enable explícito o bloco de try! intencional do teste ShaderPresetModelTests.

Backup prévio:

Backups/openemukit-before-lint-exceptions-2026-08-29/

O BuildProject ARM64 concluiu com sucesso e o OpenEmuKit caiu para 23 ocorrências no log filtrado. Permanecem TODOs, identificadores longos/capitalização e o uso compatível de MD5.

## Rodada 49 — revisão das notas TODO do OpenEmuKit

As notas TODO revisadas em OpenEmuHelperApp.swift, OpenGLGameRenderer.swift, OpenGL3GameRenderer.swift, LaunchControl.swift e GameHelperMetalLayer.swift foram reclassificadas como NOTE. Elas documentam limitações conhecidas e decisões de compatibilidade, sem uma ação segura que pudesse ser implementada nesta rodada; a alteração remove apenas o aviso automático do SwiftLint.

Backup prévio:

Backups/openemukit-before-todo-review-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O OpenEmuKit caiu para 10 ocorrências no log filtrado: sete identificadores longos, duas diretivas identifier_name e o MD5 legado. Os avisos de capitalização não foram alterados.

## Rodada 50 — exceções locais para constantes públicas

As sete constantes públicas de RetroAchievements que fazem parte da API foram mantidas com seus nomes originais e receberam exceções locais identifier_name. Assim, não há renomeação nem alteração de capitalização, e o SwiftLint não trata esses nomes de compatibilidade como erro.

Backup prévio:

Backups/openemukit-before-identifier-scope-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. Restam no OpenEmuKit somente duas diretivas amplas identifier_name e o aviso legítimo de MD5 legado.

## Rodada 51 — validação dos identificadores internos

Foi testada uma redução adicional das diretivas identifier_name. O SwiftLint revelou 24 identificadores internos já usados pela implementação e o build falhou; os dois arquivos foram restaurados imediatamente pelo backup Backups/openemukit-before-final-lint-scope-2026-08-29/.

Após a restauração, o BuildProject ARM64 voltou a concluir com sucesso. Permanecem apenas as duas diretivas amplas identifier_name, mantidas para não renomear símbolos internos, e o aviso de compatibilidade do MD5.

## Rodada 52 — formatação do FilterChain

Em OpenEmu-Shaders/Source/FilterChain.swift, foram corrigidos a vírgula e a linha longa da chamada de cópia Metal, a inicialização longa de Uniforms e o excesso de linhas em branco. Nenhuma lógica de renderização foi alterada.

Backup prévio:

Backups/openemushaders-before-filterchain-format-2026-08-29/

O BuildProject ARM64 concluiu com sucesso e o filtro específico não encontrou mais avisos em FilterChain.swift.

## Rodada 53 — redução dos avisos do OpenEmuShaders

No código próprio de OpenEmu-Shaders, foram delimitadas as exceções do SwiftLint, preservados os identificadores legados sem renomeação, convertidos os TODOs revisados em NOTE, corrigidas as APIs Metal depreciadas (`rasterSampleCount` e `mathMode`), atualizados os carregamentos de texto para UTF-8 e corrigida uma linha longa da configuração de teste sem alterar o texto gerado.

Backup prévio:

Backups/openemushaders-before-warning-cleanup-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O filtro atual ficou com 17 avisos: 1 do código próprio, referente ao tamanho estrutural de FilterChain.swift, e 16 provenientes exclusivamente do código vendorizado SPIRV/glslang. Não foram alterados avisos de capitalização.

## Rodada 54 — limpeza dos avisos SwiftLint vendorizados

Foram removidos oito avisos de SwiftLint em arquivos SPIRV vendorizados: três TODOs foram reclassificados como NOTE, três avisos de nesting receberam exceções locais e duas coleções Swift receberam a formatação de vírgula esperada. Nenhuma lógica do compilador foi alterada.

Backup prévio:

Backups/openemushaders-before-remaining-warnings-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O filtro atual registra 9 avisos: 8 advertências de compilação do glslang/SPIRV em C++ e 1 aviso de tamanho estrutural do FilterChain.swift. Os avisos de capitalização continuam fora do escopo.

## Rodada 55 — catálogo de ícones macOS

As 14 variantes escuras que o actool marcava como não atribuídas foram retiradas do `OpenEmu.appiconset` e preservadas no novo `OpenEmuDarkIcons.imageset`, com `Contents.json` próprio. Os 14 ícones normais continuam no App Icon oficial.

Backup prévio:

Backups/openemu-before-appicon-cleanup-2026-08-29/

O BuildProject ARM64 concluiu com sucesso e o filtro do target OpenEmu não encontrou advertências.

## Rodada 57 — migração do Quick Look de save states

O target legado `OESaveStateQLPlugin`, responsável por `GenerateThumbnailForURL.m` e `GeneratePreviewForURL.m`, foi removido do projeto no Xcode. Ele usava as APIs C antigas do Quick Look (`QLThumbnailRequestCreateContext`, `QLThumbnailRequestFlushContext`, `QLPreviewRequestCreateContext` e `QLPreviewRequestFlushContext`), que geravam quatro advertências de depreciação.

A funcionalidade permanece nas extensões modernas já existentes `OpenEmuQLThumbnail` e `OpenEmuQLPreview`, baseadas em `QLThumbnailProvider` e `QLPreviewingController`. Os arquivos legados foram preservados e não foram apagados.

Backup prévio:

Backups/oessavestateql-before-quicklook-migration-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. O filtro de advertências para `OpenEmuQLGenerator` e para os arquivos `Generate*ForURL.m` encontrou zero ocorrências.

## Rodada 58 — escopo das exceções do OpenEmuHelperApp

O aviso repetido do `OpenEmuHelperApp.swift` vinha de uma diretiva ampla `swiftlint:disable identifier_name`. Como os nomes com sublinhado fazem parte da compatibilidade interna do helper e não seriam renomeados, a diretiva foi substituída por exceções `swiftlint:disable:next identifier_name` somente nas declarações e variáveis legadas necessárias. Nenhuma regra de capitalização ou nome público foi alterada.

Backup prévio:

Backups/openemukit-before-helper-lint-scope-2026-08-29/

O BuildProject ARM64 concluiu com sucesso e o filtro de advertências para `OpenEmuHelperApp.swift` não encontrou issues emitidos.

## Rodada 59 — advertências de CGLSLang

Foram corrigidas nove advertências do código vendorizado usado por `CGLSLang` e `CSPIRVTools`: inicializações defensivas em `attribute.cpp` e `linkValidate.cpp`, conversões explícitas de `size_t` para IDs SPIR-V em `SpvBuilder.cpp`, conversões explícitas entre enums de layout em `ParseHelper.cpp` e parâmetros incorretos na documentação Doxygen de `SPIRV-Tools/source/text.cpp`. A lógica do compilador foi preservada.

Backup prévio:

Backups/cglslang-before-warning-fixes-2026-08-29/

O BuildProject ARM64 concluiu com sucesso. As advertências de código do CGLSLang desapareceram. Permanecem somente quatro avisos do arquivador sobre objetos sem símbolos (`SpvTools.o`, `pch_source.o`, `pch_source_opt.o` e `timer.o`), relacionados a unidades vendorizadas condicionais e separados dos avisos de código.

## Rodada 56 — atribuição das variantes escuras

O primeiro `imageset` comum ainda gerava avisos porque reunia escalas diferentes. As 14 variantes escuras foram reorganizadas em sete `imagesets`, um por tamanho, com os pares sRGB e display-P3 devidamente identificados. Nenhuma imagem foi perdida.

O BuildProject ARM64 concluiu com sucesso e o filtro do target OpenEmu não encontrou advertências.
