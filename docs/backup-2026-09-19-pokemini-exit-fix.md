# Backup e documentação — correção do encerramento do PokeMini

Data: 19 de setembro de 2026

## Problema

Ao fechar qualquer jogo do PokeMini, o OpenEmuHelperApp apresentava a tela de crash informando que o core PokeMini havia encerrado inesperadamente.

O relatório `OpenEmuHelperApp-PokeMini-crash.ips` confirmou:

- exceção `EXC_BREAKPOINT` / `SIGTRAP`;
- detecção de estouro de buffer pelo macOS;
- falha em `PokeMini_SaveSSFile`;
- uso de `strcpy` para copiar o caminho da ROM para um buffer fixo de 128 bytes.

## Correção

`PokeMini_SaveSSFile` agora usa uma cópia limitada com `snprintf`, preservando os 128 bytes reservados no formato do save state e evitando o estouro quando o caminho da ROM é longo.

## Validação

- Build do projeto concluída sem erros.
- App montado com 37 cores, incluindo PokeMini e ARMSX2.
- DMG notarizado e testado em outro Mac.
- Jogos PokeMini foram fechados sem reproduzir o crash.
- DMG publicado na release `v2.1.2`.
- Tamanho: `207681737` bytes.
- SHA-256: `ff64ac9ed796f170b2f7a5b6a6783770a328644a2f9c8778cf4c277fc9d05f10`.
- Assinatura EdDSA: `nzEvgU0hC39L5E7Z/uonBxk9tUPRRlr5OY6cZhz+wNaXoMOzxdm26/pVBtC7JVecqjUzrqSiWV+ZL/5I19YYBw==`.

## Publicação

O appcast foi atualizado em [PR #16](https://github.com/Anhani1206/OpenEmuARM/pull/16). A atualização do Sparkle ficará ativa após a mesclagem do PR.

## Backup

O backup desta etapa está em:

`Backups/2026-09-19-after-pokemini-exit-fix/`

Ele contém o DMG, o appcast, os arquivos-fonte envolvidos, os scripts de empacotamento/notarização e o relatório de crash usado na investigação.
