# FBNeo nativo para Arcade e Neo Geo

Esta integração adiciona um `FBNeo.oecoreplugin` próprio do OpenEmu. O bundle
é carregado diretamente pelo OpenEmu e não depende do scanner de cores do
RetroArch. Internamente, o plugin usa a API libretro do FinalBurn Neo como
engine, permitindo reaproveitar o host `OELibretroCoreTranslator` já usado no
projeto.

## Sistemas e formatos

- Arcade: `openemu.system.arcade`.
- Neo Geo: `openemu.system.neogeo`.
- ROMs: `.zip` e `.7z`, mantendo o romset compactado.
- BIOS Neo Geo: `neogeo.zip`, no diretório de sistema do FBNeo.

O bundle declara os dois identificadores de sistema, portanto o mesmo core
fica disponível no Arcade e na biblioteca separada Neo Geo. A seleção do core
RetroArch continua disponível como fallback quando o plugin nativo não estiver
instalado.

## Componentes

| Arquivo | Função |
|---|---|
| `FBNeo/` | Snapshot vendorizado do código FBNeo libretro. |
| `FBNeo/FBNeoGameCore.mm` | Wrapper OpenEmu baseado no host libretro existente. |
| `FBNeo/Info.plist` | Identidade, sistemas e caminho da biblioteca engine. |
| `Scripts/build-fbneo-openemu-arm64.sh` | Compila o engine e monta o bundle arm64. |
| `Scripts/install-core.sh FBNeo --release` | Instala o bundle sem mesclar arquivos antigos. |

O commit upstream usado está registrado em `FBNeo/UPSTREAM_COMMIT`. O build
usa `SUBSET=all`, `USE_SPEEDHACKS=1` e `CHD_LIBRETRO=1`; o suporte CHD fica
disponível para compatibilidade do engine, enquanto a associação de ROMs do
OpenEmu permanece focada em `.zip`/`.7z`.

## Build e instalação

```sh
CONFIGURATION=Release ./Scripts/build-fbneo-openemu-arm64.sh
./Scripts/install-core.sh FBNeo --release
./Scripts/verify-core-installed.sh FBNeo --release
```

O resultado validado do build é:

```text
/tmp/OpenEmu-FBNeo-DD/Build/Products/Release/FBNeo.oecoreplugin
```

O bundle contém `Contents/MacOS/FBNeo` e
`Contents/Resources/fbneo_libretro.dylib` (gerado de
`fbneo_all_libretro.dylib`), ambos em `arm64`, com assinatura ad-hoc válida
para teste local.

A instalação Release foi concluída em 31/08/2026 e conferida com
`verify-core-installed.sh`; o bundle instalado corresponde ao produto gerado.

## Ajustes de compatibilidade

O snapshot do FBNeo precisava de duas correções de build para o SDK atual:

1. incluir `<wchar.h>` no `tchar.h` libretro;
2. incluir `encoding_crc32.c` na lista de fontes CHD libretro, pois o linker
   usa `encoding_crc16_ccitt` e `encoding_crc32`.

Esses ajustes são de compilação e não alteram a identificação ou o conteúdo
dos romsets.

## Referências

- [Documentação do FBNeo no Libretro](https://docs.libretro.com/library/fbneo/)
- [Código oficial do FBNeo](https://github.com/finalburnneo/FBNeo)
- [Porta Libretro do FBNeo](https://github.com/libretro/FBNeo)
