# Importação de ROM corrompida

Quando uma ROM falha durante a importação por arquivo inválido, corrompido ou
ilegível, o Game Scanner pausa a fila e mostra o nome do arquivo e o motivo
informado pelo sistema.

O usuário pode escolher:

- **Skip ROM**: ignora somente o arquivo com problema e continua a fila;
- **Skip all ROM**: ignora o arquivo atual e continua automaticamente para os
  próximos arquivos com erro;
- **Stop Import**: cancela o restante da fila. Os itens concluídos permanecem
  na biblioteca.

A fila permanece pausada enquanto o alerta está aberto. A alteração foi feita
em `GameScannerViewController.swift`; a compilação foi validada com sucesso em
30 de agosto de 2026.

Os controles de pausa e parada do Game Scanner ficam na mesma linha do título
`Game Scanner` e só aparecem enquanto há uma importação ativa.
