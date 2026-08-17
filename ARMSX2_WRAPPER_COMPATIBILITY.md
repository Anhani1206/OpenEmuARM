# ARMSX2 wrapper compatibility

O procedimento técnico completo do wrapper, incluindo os símbolos libretro e
os callbacks Metal, está em
[ARMSX2_IMPLEMENTACAO_TECNICA.md](ARMSX2_IMPLEMENTACAO_TECNICA.md).

## Estado em 2026-08-12

**Progresso do wrapper OpenEmu: 85%.**

O wrapper `ARMSX2GameCore` carrega `armsx2_libretro.dylib`, configura BIOS,
recursos e memória persistente, e apresenta o renderizador Metal diretamente
na textura do OpenEmu.

### Validado

- build e instalação do `ARMSX2.oecoreplugin` em `arm64`;
- carregamento de BIOS e ISO;
- inicialização de `GS`, `SPU2`, input e demais subsistemas;
- vídeo Metal e áudio em God of War (`SCUS-97399`);
- aplicação de correções automáticas do GameDB;
- atualização de `GameIndex.yaml` e dos `.metallib` persistentes quando o
  bundle é substituído.
- ciclo de vida do wrapper reforçado: falhas de boot desmontam o core, os
  callbacks Metal são removidos antes do encerramento e os dois controles
  DualShock 2 são declarados explicitamente.
- save states agora retornam erros claros quando não há jogo em execução ou o
  core ainda não disponibilizou um buffer de estado.

### Compatibilidade Metal corrigida

- shader libraries agora são compiladas do fonte ARMSX2 com o Metal Toolchain;
- incompatibilidades de layout de constantes que pertenciam às bibliotecas
  antigas do PCSX2 foram removidas do caminho nativo;
- a falha `Failed to load shader ps_main` foi resolvida;
- a tela vermelha sólida em God of War foi eliminada.

### Pendente

- regressão de Gran Turismo 4 e outros jogos com múltiplas camadas de composição;
- input em jogo, memory cards, save/load state e ciclos repetidos de abertura;
- medição de desempenho e estabilidade prolongada;
- flash rosa transitório anterior ao primeiro frame real, sem impacto durante
  a execução.

## Rota ARMSX2

```sh
Scripts/build-armsx2-libretro-arm64.sh
Scripts/install-debug-armsx2-core.sh \
  /tmp/OpenEmu-Shared-DD/Build/Products/Debug/ARMSX2.oecoreplugin
```

## Rota Rosetta fallback

```sh
Scripts/build-rosetta-openemu-pcsx2.sh
Scripts/install-debug-pcsx2-core-rosetta.sh
Scripts/run-openemu-rosetta-pcsx2.sh
```
