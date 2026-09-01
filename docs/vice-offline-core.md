# VICE offline para Commodore 64

O Commodore 64 usa o core VICE Libretro, empacotado pelo
`Scripts/build-vice-openemu-arm64.sh` como:

```text
VICE.oecoreplugin/Contents/Resources/vice_x64_libretro.dylib
```

O wrapper aponta para a biblioteca por caminho relativo e declara o sistema
`openemu.system.c64`. O `Scripts/release.sh` compila o core em Release arm64 e
o copia para `OpenEmu.app/Contents/PlugIns/Cores/`, junto com os demais cores
offline. Na primeira execução, o fluxo de cores integrados copia esse bundle
para a pasta local de cores do OpenEmu.

O build parte do repositório oficial `libretro/vice-libretro` em um checkout
temporário. O VICE Libretro informa que os arquivos de firmware são opcionais
porque os dados necessários são embutidos no core; os arquivos pessoais do
usuário, como imagens `.d64`, `.d81`, `.crt`, `.prg`, `.tap` e `.x64`, continuam
sendo as mídias dos jogos e não são distribuídos pelo projeto.

## Imagem de controles

O painel de Controles usa `controller_c64.png`, em PNG RGBA com fundo
transparente. A imagem é mantida proporcionalmente em 500 × 316 px para caber
no espaço disponível sem cortar o computador. Para evitar que o teclado fique
baixo no painel, o C64 usa centralização vertical específica no
`ControllerImageView`. O asset e o código anterior foram preservados em
`Backups/vice-c64-offline-2026-09-01/`.

O script aplica duas correções locais para o Xcode atual: inclui o diretório
`vice/src/crtc` e evita que o zlib antigo redefina `fdopen` no macOS. Nenhuma
dessas correções altera o checkout do projeto.

Validação mínima:

```sh
CONFIGURATION=Release ./Scripts/build-vice-openemu-arm64.sh
file /tmp/OpenEmu-VICE-DD/Build/Products/Release/VICE.oecoreplugin/Contents/Resources/vice_x64_libretro.dylib
lipo -info /tmp/OpenEmu-VICE-DD/Build/Products/Release/VICE.oecoreplugin/Contents/Resources/vice_x64_libretro.dylib
```

Referência técnica: [VICE Libretro documentation](https://docs.libretro.com/library/vice/).
