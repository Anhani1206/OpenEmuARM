# Ícone do OpenEmu no modo escuro

## Comportamento

O OpenEmu usa a imagem fornecida `OpenEmuARM-iOS-Dark-1024@1x.png` como ícone quando a aparência efetiva do aplicativo é `darkAqua`. No modo claro, o ícone original do bundle é restaurado.

## Implementação

- Os tamanhos escuros ficam em `OpenEmu/Graphics.xcassets/OpenEmuDarkIcon*.imageset`.
- As variantes também estão registradas no `OpenEmu.appiconset`.
- `OpenEmu/Sources/AppDelegate.swift` atualiza `NSApp.applicationIconImage` quando a preferência de aparência muda.
- O método usa `NSImage(named: "OpenEmuDarkIcon1024")` no modo escuro e `nil` no modo claro para restaurar o ícone do bundle.

## Teste

1. Compile e execute uma nova versão do OpenEmu.
2. Selecione a aparência escura em Preferências ou use o modo escuro do sistema.
3. Confirme o ícone no Dock.
4. Alterne para o modo claro e confirme que o ícone original retorna.

Se o Dock continuar mostrando a versão anterior, encerre e reabra o OpenEmu; o Finder/Dock pode manter o ícone antigo em cache.
