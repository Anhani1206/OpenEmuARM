# Cores incluídos no pacote Release

O aplicativo pode distribuir cores dentro de
`OpenEmu.app/Contents/PlugIns/Cores/`, permitindo uma instalação inicial sem
acesso à internet ou aos appcasts.

## Escopo atual

O `release.sh` agora exige e copia para o DMG todos os cores nativos com
projeto disponível neste checkout: 4DO, Mupen64Plus, MAME, Stella, Atari800,
ProSystem, VirtualJaguar, Mednafen, JollyCV, CrabEmu, blueMSX, Nestopia, FCEU,
Gambatte, mGBA, Dolphin, Bliss, O2EM, GenesisPlus, Flycast, Picodrive,
SNES9x, BSNES, VecXGL, Potator, DeSmuME e PPSSPP.

Também são incluídos os cores adicionados ao fork: ARMSX2, FBNeo e
Geolith-RetroArch e VICE para Commodore 64. O VICE é compilado em ARM64 e
copiado como um bundle relativo com os dados da máquina embutidos; portanto o
usuário não precisa instalar RetroArch, baixar o core ou acessar Appcasts.
Pokémon Mini permanece excluído por decisão do projeto.

DeSmuME e PPSSPP possuem projetos nativos no checkout e fazem parte da matriz
de build Release. Ambos foram validados em arm64. O PPSSPP exige o relink
automático previsto em `release.sh`, pois o projeto achatado não inclui
`glew.c` no target; o script compila esse objeto e o adiciona ao comando de
link original do Xcode antes de copiar o bundle para o app.

O 4DO e o Mupen64Plus são compilados como produtos Release novos. O
OpenEmuBase Release é construído antes deles para fornecer headers e o
framework usados pelos cores.

O `Scripts/release.sh` compila os cores Release, copia-os para o pacote do
app e valida cada bundle. ARMSX2, Geolith, FBNeo e VICE são construídos pelos
seus scripts próprios; os demais são construídos pelos seus projetos Xcode.

O VICE usa `vice_x64_libretro.dylib` para os formatos do Commodore 64 já
registrados pelo plugin de sistema (`crt`, `d64`, `d71`, `d81`, `g64`, `p00`,
`p64`, `prg`, `t64`, `tap` e `x64`). As correções de compatibilidade do SDK
atual são aplicadas somente ao checkout temporário de build.

Na primeira execução, `AppDelegate` sincroniza os bundles marcados com
`OEBundledCoreRefreshRevision` para:

```text
~/Library/Application Support/OpenEmu/Cores/
```

Essa cópia local permite que a descoberta normal de cores funcione sem
download. O aplicativo deve ser assinado novamente depois que os cores forem
incorporados; a assinatura da equipe Apple será configurada na etapa de
notarização.

## Verificação antes da distribuição

```sh
./Scripts/release.sh <versão>
```

Após a criação do archive, confirme que todos os bundles nativos existem em:

```text
OpenEmu.app/Contents/PlugIns/Cores/
```

Não devem ser incluídos arquivos de build, DerivedData ou bundles Debug na
distribuição.

## Estado da implementação

O bloqueio de Release foi corrigido:

- o scheme do 4DO usa uma referência de container válida;
- o 4DO recebe os headers e o framework Release do OpenEmuBase;
- os arquivos Android do GLideN64 não entram mais no target macOS do Mupen64Plus;
- os targets do Mupen recebem os headers legados necessários e o framework
  Release do OpenEmuBase;
- nenhum produto Debug é reutilizado.

Validação realizada em 1º de setembro de 2026:

- OpenEmuBase Release: compilado com sucesso;
- 4DO Release: compilado com sucesso, arm64 e x86_64;
- Mupen64Plus Release: compilado com sucesso, arm64, incluindo GLideN64,
  angrylion e os plugins RSP.

O archive completo ainda deve ser executado com as credenciais da equipe Apple
antes da notarização.
