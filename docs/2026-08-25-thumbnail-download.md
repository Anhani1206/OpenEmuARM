# Download de thumbnails

## Problema

Ao baixar capas de muitos jogos Nintendo, algumas respostas dos provedores eram páginas PHP, JSON ou arquivos JPEG inválidos. O ImageKit tentava criar thumbnails desses arquivos e gerava erros `CGImageSourceCreateThumbnailAtIndex` no console.

## Correções

- As imagens baixadas são validadas antes de serem gravadas na biblioteca.
- O cache rejeita arquivos que não podem ser decodificados.
- A grade recebe uma `NSImage` validada, em vez do caminho do JPEG diretamente.
- O download ocorre em segundo plano, sem bloquear a interface.
- O processo pode ser interrompido entre downloads; as imagens já salvas são preservadas.

## Menu

Ao clicar com o botão direito em um console na barra lateral, abra:

**Thumbnails**

- **Download all thumbnails** — baixa as capas que ainda não estão disponíveis localmente.
- **Stop thumbnail download** — solicita a parada do processo.

## Validação

A build passou e o aplicativo foi iniciado pelo Xcode sem erros de compilação.
