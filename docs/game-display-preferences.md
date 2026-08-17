# Preferências de exibição por jogo

O OpenEmu guarda as últimas preferências de exibição para cada ROM, usando o
identificador MD5 dela e o identificador do sistema. Assim, jogos diferentes do
mesmo console podem usar configurações diferentes sem se afetarem.

## O que é guardado

- shader ou preset de shader selecionado;
- escala inteira da janela;
- escala escolhida em tela cheia.

As preferências são gravadas assim que o shader ou a escala é alterado e são
restauradas na próxima abertura do mesmo jogo. Caso um jogo ainda não tenha
preferências próprias, o OpenEmu usa as preferências existentes do sistema
como valor inicial.

## Manutenção

As chaves ficam em `UserDefaults` e incluem sistema + MD5 da ROM. Não use o
nome do arquivo como chave: ele pode mudar quando a ROM é renomeada, enquanto
o MD5 mantém a configuração associada ao mesmo conteúdo.
