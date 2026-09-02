# Progresso da compilação do MAME

Data: 2 de setembro de 2026

## Ponto em que parou

A compilação do MAME foi interrompida manualmente porque o Mac ficou sem resposta.
O processo estava na compilação dos arquivos-fonte do MAME, depois de gerar os
Makefiles e iniciar a configuração `macosx_arm64_clang` em modo Release.

Estado encontrado após a interrupção:

- 317 arquivos objeto intermediários presentes;
- aproximadamente 1.549 arquivos-fonte identificados pelo gerador;
- `mamearcade_headless.dylib` ainda não gerada;
- `MAME.oecoreplugin` ainda não gerado;
- diretório intermediário: `MAME/deps/mame/build`;
- tamanho do diretório intermediário: aproximadamente 93 MB.

Isso indica que a compilação estava aproximadamente em 20%, e não próxima da
etapa final de linkedição. Os objetos intermediários devem permitir que a
próxima tentativa reutilize parte do trabalho já concluído.

## Próxima tentativa

Executar a mesma compilação com paralelismo limitado, começando por `-j4`:

```bash
./Scripts/build-mame-core.sh
```

Antes disso, ajustar temporariamente o número de tarefas usado pelo script para
`-j4`. Se a compilação ficar estável, uma tentativa posterior pode usar `-j6`.

## Resultado da tentativa com `-j4`

A compilação foi concluída com sucesso usando `-j4` antes da pausa solicitada.
Os dois binários ARM64 foram gerados:

- `MAME/build/XcodeDerived/Build/Products/Release/MAME.oecoreplugin`;
- `MAME/deps/mame/mamearcade_headless.dylib`.

O plugin foi incorporado e assinado no app de validação com os outros 31 cores.
O pacote agora contém 32 cores e ocupa aproximadamente 527 MB. A validação
profunda da assinatura do app foi concluída com sucesso. Nenhum release ou
notarização foi iniciado nesta etapa.
