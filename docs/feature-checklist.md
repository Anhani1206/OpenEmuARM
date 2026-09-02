# Checklist de funcionalidades do OpenEmu-Silicon

Este arquivo reúne as funcionalidades registradas em `docs/` para acompanhar
o que já foi implementado, o que precisa ser validado e o que ainda é trabalho
futuro.

## Cores e sistemas

### Cores incluídos offline no DMG

O `Scripts/release.sh` compila e incorpora estes bundles no aplicativo Release;
eles não dependem de Appcast ou download inicial pelo usuário:

- [x] 4DO, Mupen64Plus, MAME, Stella, Atari800, ProSystem e VirtualJaguar.
- [x] Mednafen, JollyCV, CrabEmu, blueMSX, Nestopia e FCEU.
- [x] Gambatte, mGBA, Dolphin, Bliss, O2EM, GenesisPlus e Flycast.
- [x] Picodrive, SNES9x, BSNES, VecXGL, Potator, DeSmuME e PPSSPP.
- [x] ARMSX2, FBNeo, Geolith e VICE.
- [x] Commodore 64: VICE com dados da máquina incorporados no bundle.
- [x] Pokémon Mini permanece excluído da distribuição offline por decisão do projeto.

Detalhes do empacotamento e da validação estão em
[bundled-core-packaging.md](bundled-core-packaging.md).

- [x] 3DO: remover Opera da seleção de cores.
- [x] 3DO: escala integral funcionando acima de 1× — OK.
- [x] 3DO: controles do Wii.
- [x] 3DO: escala integral documentada em [2026-08-23-3do-mupen-cheat-search.md](2026-08-23-3do-mupen-cheat-search.md).
- [x] Mupen64Plus: Cheat Search.
- [x] Mupen64Plus: iniciar em 320×240 para habilitar escala integral.
- [x] Neo Geo separado na interface usando FBNeo.
- [x] Geolith como opção Neo Geo e core Release portátil.
- [x] FBNeo nativo para Arcade e Neo Geo — bundle Release arm64 instalado e verificado. Ver [fbneo-native-integration.md](fbneo-native-integration.md).
- [x] Nomes dos cores de Arcade, menu contextual e System Files padronizados sem “RetroArch”. Ver [arcade-core-display-names.md](arcade-core-display-names.md).
- [x] MAME 2003 para Arcade.
- [x] Seleção automática de core por ROM set.
- [x] Seleção de core salva por jogo.
- [x] PlayStation 2 com ARMSX2 em Release otimizado — instalado e verificado.
- [x] Cópias portáteis dos cores e bibliotecas padrão.
- [x] Commodore 64 com VICE Libretro offline, empacotado no Release arm64.

## Vídeo, biblioteca e importação

- [x] FPS Overlay configurável.
- [x] Rotação da tela em incrementos de 90 graus.
- [x] Game Mode do macOS.
- [x] Controles de pausa e parada do Game Scanner.
- [x] Escolha para ROM inválida ou corrompida.
- [x] Download de thumbnails com validação das respostas.
- [x] Download de Cover Arts pelo menu contextual da barra lateral.
- [x] Ícone alternativo no modo escuro.
- [x] Arte e controles do PlayStation 2.
- [ ] Revisar e reduzir advertências restantes do Xcode.

## RetroAchievements

- [x] Integração do `rc_client` nos cores nativos.
- [x] Modo hardcore.
- [x] Processamento offline e fila de eventos.
- [x] Save-state progress.
- [ ] Concluir submissão e aprovação oficial junto ao RetroAchievements.

Referências: [guia de implementação](retro-achievements/retroachievements-implementation-guide.md),
[evidências de conformidade](retro-achievements/retroachievements-compliance-evidence.md)
e [guia da comunidade](retro-achievements/retroachievements-community-guide.md).

## Serviços e distribuição

- [x] Integração com ScreenScraper.
- [x] Atualização dos links públicos para o repositório correto.
- [x] Atualização dos feeds de atualização dos cores.
- [x] Distribuição portátil com os cores integrados.
- [x] DeSmuME incluído na matriz de cores nativos Release e validado em arm64.
- [x] PPSSPP incluído na matriz de cores nativos Release e validado em arm64.
- [x] PPSSPP: relink Release offline com GLEW vendorizado automatizado no empacotador.
- [ ] Backup configurável em pasta local, iCloud Drive ou Dropbox.

O backup em pasta ainda está descrito como plano em
[folder-backup-design.md](superpowers/specs/2026-05-11-folder-backup-design.md)
e [folder-backup.md](superpowers/plans/2026-05-11-folder-backup.md).

## Documentação de referência

- [ ] Auditar a matriz de suporte dos cores.
- [x] VICE avaliado e integrado como core libretro offline para Commodore 64.
- [ ] Manter atualizada a arquitetura do Libretro.
- [ ] Atualizar a política de privacidade quando novos serviços forem adicionados.
- [ ] Usar o guia de worktrees nas validações de branches paralelos.
