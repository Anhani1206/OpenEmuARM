# Matriz de teste — Libretro Cheat Database 2.1

Use esta matriz para testar a build local. Os testes devem ser feitos com um jogo conhecido por sistema e, sempre que possível, com o core indicado abaixo.

## Sistemas e cores suportados

| ✓ | Sistema | Core | Verificações principais |
|---|---|---|---|
| ✅ | Atari 2600 | Stella | Abrir navegador, encontrar cheats, importar e ativar |
| ✅ | ColecoVision | CrabEmu | Encontrar cheats e confirmar ativação no jogo |
| ✅ | Famicom Disk System | Nestopia | Encontrar cheats e confirmar troca de disco não quebra a janela |
| ✅ | Game Boy | Gambatte | Encontrar cheats, importar e persistir após reabrir o jogo |
| ✅ | Game Boy Color | Gambatte | Repetir o teste usando um jogo GBC; o sistema usa o mesmo identificador interno do Game Boy |
| ✅ | Game Boy Advance | mGBA | Encontrar cheats CodeBreaker/GameShark e ativar um código |
| ✅ | Game Gear | GenesisPlus | Encontrar cheats e confirmar ativação |
| ✅ | Genesis / Mega Drive | GenesisPlus | Encontrar cheats, importar e ativar |
| ✅ | Master System | GenesisPlus | Encontrar cheats e ativar um código |
| ✅ | Master System | CrabEmu | Repetir o teste com CrabEmu |
| ✅ | NES / Famicom | FCEU | Validar Game Genie e código hexadecimal |
| ✅ | NES / Famicom | Nestopia | Validar Game Genie/Pro Action Rocky e ativação |
| ✅ | Nintendo 64 | Mupen64Plus | Encontrar código GameShark e ativar |
| ✅ | Nintendo DS | DeSmuME | Encontrar código Action Replay; testar filtro por nome |
| ✅ | PlayStation | Mednafen | Encontrar código de jogo, importar e ativar |
| ✅ | Sega CD | GenesisPlus | Confirmar identificação por jogo/disco e carregar cheats |
| ✅ | SG-1000 | GenesisPlus | Encontrar cheats e confirmar ativação |
| ✅ | SNES | BSNES | Encontrar cheats e ativar um código |
| ✅ | SNES | SNES9x | Repetir o teste com SNES9x |

## Roteiro por jogo

Para cada linha aplicável:

1. Inicie o jogo usando o core indicado.
2. Abra `Controls > Select Cheat > Browse Online Cheats…`.
3. Confirme que o jogo, MD5 e core aparecem corretamente.
4. Confirme que a lista carrega sem erro e que o filtro por nome funciona.
5. Use os indicadores `Working`, `Not Working` e `Not set`.
6. Importe um cheat compatível.
7. Confirme que ele aparece no menu `Select Cheat` e pode ser ativado/desativado.
8. Feche e reabra a janela para confirmar que o cheat importado permanece salvo.
9. Feche e reabra o jogo para confirmar a persistência.

## Casos negativos

- Abrir um sistema fora desta matriz: `Browse Online Cheats…` não deve aparecer.
- Selecionar um core diferente do indicado: o recurso não deve ser oferecido quando o core não estiver na matriz validada.
- Pesquisar um nome inexistente: a lista deve informar que não há resultados, sem travar.
- Rom sem correspondência no Libretro: a janela deve permanecer utilizável e permitir fechar normalmente.
- Falha de rede após um carregamento anterior: o cache local deve continuar disponível.

## Resultado

| Data | Build/commit | Sistemas aprovados | Falhas | Observações |
|---|---|---:|---:|---|
| 2026-09-07 | Local Debug build — 19/19 aprovados | 19 | 0 | Todos os sistemas/cores da matriz validados manualmente |
