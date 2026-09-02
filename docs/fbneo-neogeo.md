# Neo Geo com FBNeo

## Regra de seleção por formato

- Arquivos `.neo` são abertos exclusivamente pelo **Geolith**.
- Arquivos `.zip` são abertos exclusivamente pelo **FBNeo nativo**.
- O **FinalBurn Neo via RetroArch** e o subconjunto Neo Geo não aparecem nos
  menus de seleção.

Essa apresentação é igual nos menus **Default Core**, **Play With…** e
**Select Core**. No menu padrão do sistema, sem um jogo selecionado, Geolith e
FBNeo são mostrados como as duas opções possíveis.

O OpenEmu-Silicon disponibiliza Neo Geo como um sistema separado na barra lateral. A emulacao e fornecida pelo **FinalBurn Neo (FBNeo)**, que e o unico core exposto para esse sistema.

Internamente, Neo Geo usa o perfil de entrada Arcade (`OESystemTypeArcade` e `OESystemMediaArcadeROM`). O plugin final e derivado do plugin Arcade para preservar `OEArcadeSystemResponder`, que encaminha corretamente Coin, Start e os botoes ao FBNeo, embora a interface continue a apresenta-lo como **Neo Geo** separado.

O plugin tambem fornece seu proprio `OENeoGeoSystemResponder`. Ele nao pode apontar diretamente para o responder do plugin Arcade, pois o processo auxiliar carrega cada plugin de sistema de forma isolada.

## Instalar o core

O FBNeo nao e distribuido junto com o OpenEmu. O projeto FBNeo tem licenca de uso nao comercial, por isso o core deve ser obtido e instalado localmente pelo utilizador.

1. Compile ou obtenha um core libretro arm64 compativel, por exemplo `fbneo_neogeo_libretro.dylib`.
2. Coloque o ficheiro em `~/Library/Application Support/RetroArch/cores/`.
3. Coloque o ficheiro de descricao correspondente (`fbneo_neogeo_libretro.info`) em `~/Library/Application Support/RetroArch/info/`.
4. Reinicie o OpenEmu. Em **Preferences > Cores > Neo Geo**, apenas o FinalBurn Neo deve aparecer.

Para uma compilacao feita com os comandos abaixo, a instalacao local pode ser feita com:

```bash
mkdir -p "$HOME/Library/Application Support/RetroArch/cores" \
         "$HOME/Library/Application Support/RetroArch/info"
cp -f /private/tmp/fbneo-openemu/src/burner/libretro/fbneo_neogeo_libretro.dylib \
      "$HOME/Library/Application Support/RetroArch/cores/"
curl -fL https://raw.githubusercontent.com/libretro/libretro-super/master/dist/info/fbneo_neogeo_libretro.info \
      -o "$HOME/Library/Application Support/RetroArch/info/fbneo_neogeo_libretro.info"
```

O OpenEmu deteta tanto os nomes `FBNeo` como `FinalBurn Neo` no ficheiro `.info`. Quando o mesmo core declara Arcade, ele tambem e apresentado para Neo Geo.

## BIOS e ROMs

- Use ROMs que correspondam exatamente ao romset da mesma versao do FBNeo.
- Mantenha os jogos em ficheiros `.zip`; nao os extraia.
- Em **Preferences > System Files**, arraste `neogeo.zip` para a entrada **Neo Geo BIOS (FBNeo)**. O OpenEmu coloca o ficheiro em `OpenEmu/BIOS/fbneo/neogeo.zip`, que a ponte libretro fornece ao core como diretorio de sistema/BIOS.
- O mesmo ficheiro e sincronizado automaticamente para `OpenEmu/FBNeo/system/neogeo.zip`, usado pelo plugin nativo **FinalBurn Neo**. Nao e necessario manter duas copias manualmente.
- Ao importar um `.zip`, escolha **Neo Geo** se o OpenEmu apresentar uma escolha entre Arcade e Neo Geo.

Ficheiros de outro romset podem aparecer na biblioteca mas falhar ao iniciar; normalmente isso indica uma incompatibilidade de versao do romset, e nao um problema do OpenEmu.

## Aparencia na interface

O sistema usa um icone compacto proprio (`neogeo_icon`) na barra lateral. A tela **Preferences > Controls > Neo Geo** usa a ilustracao do controle Neo Geo (`controller_arcade`) e sua mascara de destaque. Os tres recursos pertencem ao catalogo de imagens do alvo `NeoGeo`; eles devem continuar com esses nomes, pois sao carregados pelo plugin em tempo de execucao.

## Quando todos os cores encerram com o mesmo aviso

Se o jogo aparece na biblioteca, a BIOS `neogeo.zip` e reconhecida, mas qualquer core de Neo Geo encerra logo ao abrir, confirme primeiro o romset. O arquivo do jogo e `neogeo.zip` precisam pertencer a versao exata do core selecionado (por exemplo, FBNeo). Trocar apenas o core no OpenEmu nao converte a ROM para outro romset.

## Compilar apenas o subconjunto Neo Geo (desenvolvimento)

No checkout oficial `libretro/FBNeo`, execute de forma serial. O Makefile gera a lista de drivers e pode falhar quando essa etapa corre em paralelo com a linkagem.

```bash
make -C src/burner/libretro clean SUBSET=neogeo
make -C src/burner/libretro REGEN_HEADERS=1 SUBSET=neogeo
```

O resultado e `src/burner/libretro/fbneo_neogeo_libretro.dylib` para Apple Silicon.
