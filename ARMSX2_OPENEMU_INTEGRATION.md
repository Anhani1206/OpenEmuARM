# ARMSX2 no OpenEmu

Para o guia consolidado de requisitos, diagnóstico e validação de PlayStation
2 e Neo Geo, consulte [docs/ps2-neogeo-implementation.md](docs/ps2-neogeo-implementation.md).

Para o inventário completo de arquivos, arquitetura Metal, build, instalação,
recursos persistentes e diagnóstico, consulte
[ARMSX2_IMPLEMENTACAO_TECNICA.md](ARMSX2_IMPLEMENTACAO_TECNICA.md).

## Status em 2026-08-12

ARMSX2 é a rota experimental ativa para PlayStation 2 nativo em `arm64` no
OpenEmu. O núcleo `ARMSX2-Core` vem de `ARMSX2/ARMSX2`, commit `788a59d`, e é
empacotado como `ARMSX2.oecoreplugin` por meio de um wrapper OpenEmu/libretro.

**Progresso da integração ARMSX2: 78%.** Esta porcentagem cobre a integração,
não a compatibilidade completa da biblioteca de jogos.

| Área | Estado | Progresso |
|---|---|---:|
| Build, assinatura e instalação `arm64` | Validado | 100% |
| Ponte Metal direta para o OpenEmu | Validada em God of War | 95% |
| Bibliotecas de shader Metal | Compiladas do fonte ARMSX2 usando o Metal Toolchain | 100% |
| Inicialização, vídeo e áudio | Validados em God of War (`SCUS-97399`) | 80% |
| GameDB e recursos persistentes | Validados; recursos são atualizados quando o bundle muda | 90% |
| Compatibilidade entre jogos | Parcial; Gran Turismo 4 ainda requer regressão | 45% |
| Input, memory cards, save/load state e encerramento repetido | Ainda não validados sistematicamente | 20% |

## Correções concluídas

- A apresentação Metal agora usa a textura direta do OpenEmu; o fallback de
  vídeo por CPU é suprimido depois do primeiro quadro Metal válido.
- O seletor de vertex shader voltou a usar os valores do estágio de vértice,
  evitando composições incompletas em jogos como Gran Turismo 4.
- O script de build local detecta uma instalação completa do Xcode quando
  `xcode-select` aponta apenas para Command Line Tools. Isso permite gerar
  `default.metallib`, `Metal22.metallib` e `Metal23.metallib` do próprio fonte
  ARMSX2, em vez de reutilizar bibliotecas do PCSX2.
- As constantes de função usadas apenas para compatibilidade com as antigas
  bibliotecas PCSX2 foram removidas do caminho de shader nativo. Elas causavam
  o erro `ROV_NEEDS_R32 ... Bool ... UInt`, bloqueando `ps_main` e deixando
  vídeo e áudio sem iniciar.
- O wrapper sincroniza `GameIndex.yaml` e as bibliotecas Metal do bundle para
  os recursos persistentes do OpenEmu quando o conteúdo muda.
- O wrapper limpa os callbacks Metal antes de descarregar a biblioteca,
  desmonta corretamente uma tentativa de boot que falha e inicializa os dois
  controles DualShock 2 de forma explícita.
- God of War (`SCUS-97399`) inicia com vídeo e áudio; o GameDB aplica
  `autoFlush=1` e `halfPixelOffset=5`.

## Limitação conhecida

Há um flash rosa breve antes do primeiro quadro do jogo. A leitura da textura
Metal do ARMSX2 mostra preto até o início do conteúdo real, portanto esse flash
é da transição da superfície do OpenEmu e não da renderização persistente do
jogo. Não afeta vídeo ou áudio durante a execução.

## Próximos testes

1. Revalidar Gran Turismo 4 após os shaders nativos, incluindo menus, corrida
   e composição de HUD.
2. Validar input, memory cards, save/load state e encerramento limpo em God of
   War.
3. Medir desempenho em títulos pesados antes de promover ARMSX2 além de
   experimental.
4. Manter PCSX2 via Rosetta como fallback até que a matriz funcional seja
   fechada.

## Comandos ativos

```sh
Scripts/build-armsx2-libretro-arm64.sh
Scripts/install-debug-armsx2-core.sh \
  /tmp/OpenEmu-Shared-DD/Build/Products/Debug/ARMSX2.oecoreplugin
```

## Rota fallback: PCSX2 via Rosetta

```sh
Scripts/build-rosetta-openemu-pcsx2.sh
Scripts/install-debug-pcsx2-core-rosetta.sh
Scripts/run-openemu-rosetta-pcsx2.sh
```
