# Core por jogo

O OpenEmu agora guarda o core que carregou cada jogo com sucesso.

## Comportamento

- A preferência é associada ao identificador permanente do jogo na biblioteca.
- Ao abrir normalmente um jogo, o core salvo é tentado primeiro.
- A opção `Play With…` continua permitindo escolher outro core manualmente.
- A preferência só é gravada depois que o documento confirma que o core carregou.
- Se o core for removido ou deixar de atender ao sistema, a seleção salva é ignorada e o OpenEmu usa a seleção padrão.

Isso permite manter, por exemplo, MAME 2003 0.78 para jogos do romset MAME 2003, sem alterar o core padrão dos demais jogos Arcade. A regra é independente do Geolith: arquivos `.neo` continuam usando Geolith e arquivos `.zip` de Neo Geo continuam usando FinalBurn Neo.
