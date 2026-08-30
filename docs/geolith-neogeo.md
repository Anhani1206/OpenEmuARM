# Geolith no Neo Geo

O OpenEmu reconhece o Geolith como core RetroArch do sistema Neo Geo. O FBNeo continua sendo o core padrão; o Geolith aparece como uma opção adicional em Preferências → Cores → Neo Geo quando os arquivos do core estão instalados.

O plugin Libretro é adicionado pelo menu de Cores e não oferece uma ação de remoção no OpenEmu. O arquivo original do core continua sendo administrado pelo RetroArch.

## Instalação do core

Instale estes dois arquivos nas pastas do RetroArch:

- `~/Library/Application Support/RetroArch/cores/geolith_libretro.dylib`
- `~/Library/Application Support/RetroArch/info/geolith_libretro.info`

O arquivo `.info` deve declarar `corename = "Geolith"` e `systemid = "neogeo"`. Ao reabrir as Preferências, a opção **Geolith (RetroArch)** será associada à biblioteca Neo Geo.

## BIOS e jogos

O Geolith aceita jogos de cartucho no formato `.neo`. A documentação oficial lista `.neo` como a extensão suportada pelo core.

O menu **Play With…** só apresenta o Geolith para jogos `.neo`. ROMs `.zip` de conjuntos FBNeo continuam sendo executadas pelo FBNeo.

As BIOS reconhecidas pelo OpenEmu são:

- `aes.zip` — MD5 `ad9585c72130c56f04ae26aae87c289d`
- `neogeo.zip` — MD5 `00dad01abdbf8ea9e79ad2fe11bdb182`

Os dois arquivos ficam diretamente na pasta `OpenEmu/BIOS`, sem uma subpasta `geolith`.

O Geolith é um core externo do ecossistema Libretro; seus fontes não são incorporados ao repositório do OpenEmu. A implementação apenas faz o mapeamento correto do core, sistema e BIOS na tela de Preferências.

## Correção aplicada em 25/08/2026

O jogo não carregava mesmo com ROM e BIOS válidos porque o tradutor Libretro não entregava o diretório de BIOS ao Geolith durante `retro_load_game`. O core abortava antes de ler `aes.zip` ou `neogeo.zip`.

A correção no `OELibretroCoreTranslator`:

- fornece sempre o caminho real de `OpenEmu/BIOS`;
- fornece um diretório válido para saves/battery saves;
- fixa os padrões oficiais do Geolith: AES e região US;
- atualiza a versão da ponte para `12`, propagando a correção aos stubs RetroArch instalados.

Resultado validado: o arquivo `.neo` de teste **3 Count Bout ~ Fire Suplex** passou a iniciar pelo Geolith.

## Diagnóstico e correção final — 30/08/2026

Quando o jogo continuava falhando, o log do helper mostrou:

```text
ROM exists=1 size=0 need_fullpath=1 BIOS aes=1 neogeo=1
```

O arquivo estava correto — o CRC32 de `3 Count Bout ~ Fire Suplex (NGM-043)(NGH-043).neo` era `03bdc5a6` — e as duas BIOS tinham os hashes esperados. O problema era o caminho do jogo: o Geolith instalado reportava `need_fullpath=1` e recebia diretamente um arquivo em `Downloads`, enquanto o helper não tinha um caminho local estável para o core abrir.

A correção final no tradutor Libretro:

- resolve BIOS, suporte e saves somente depois que o helper está ligado ao controlador;
- cria um diretório válido de saves quando o controlador não fornece um;
- copia temporariamente o `.neo` para `OpenEmu/Geolith Content`;
- entrega ao Geolith o caminho local copiado, respeitando `need_fullpath=1`;
- mantém o modo padrão do conjunto `FBNeo Based` como `Neo Geo MVS (Arcade)`.

O build foi validado no Xcode e o jogo iniciou corretamente pelo Geolith. O FinalBurn Neo continua responsável pelos arquivos `.zip`; o MAME 2003/0.78 permanece separado para seus próprios romsets.

## Correção da exclusão em massa

Em 25/08/2026, a exclusão de vários jogos Neo Geo podia deixar o app sem resposta. A causa era a chamada síncrona de `NSWorkspace.recycle` para cada ROM e save state na thread principal.

A movimentação para o Lixo agora usa uma fila de baixa prioridade. A remoção dos objetos do banco continua no contexto principal, mas a interface não fica bloqueada enquanto os arquivos são movidos.

Referências:

- [Documentação oficial do Geolith](https://docs.libretro.com/library/geolith/)
- [Repositório oficial Geolith Libretro](https://github.com/libretro/geolith-libretro)
