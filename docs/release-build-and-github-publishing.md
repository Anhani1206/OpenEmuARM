# Procedimento de build Release e publicação no GitHub

Guia para repetir o processo em outro Mac/Xcode. Os comandos abaixo devem ser executados na raiz do projeto.

## 1. Abrir o workspace correto

```bash
cd ~/Documents/GitHub/OpenEmuARM
git status
git branch --show-current
xcodebuild -list -workspace OpenEmu.xcworkspace
```

Confirme que o workspace contém o scheme `OpenEmu`. Não misture esta cópia com o worktree da versão 3.0.

Abra o workspace no Xcode:

```bash
open OpenEmu.xcworkspace
```

Resolva primeiro qualquer alteração local inesperada. Não faça `reset --hard` sem criar uma cópia de segurança.

## 2. Preparar credenciais e dependências

Os arquivos secretos devem ser gerados apenas a partir dos templates:

```bash
cp OpenEmu/ScreenScraperDevCredentials.template.swift OpenEmu/ScreenScraperDevCredentials.swift
cp OpenEmu/OEGoogleDriveSecrets.template.swift OpenEmu/OEGoogleDriveSecrets.swift
```

No Xcode, faça uma build Debug ou abra o projeto e aguarde o Swift Package Manager resolver o Sparkle. Isso disponibiliza o `sign_update` usado na assinatura EdDSA.

Para notarização, o perfil de credenciais deve existir no Keychain:

```bash
xcrun notarytool history --keychain-profile OpenEmu
```

Se necessário, crie-o usando o Apple ID correto, Team ID e uma senha específica de app gerada em `appleid.apple.com`:

```bash
xcrun notarytool store-credentials OpenEmu \
  --apple-id "SEU_APPLE_ID" \
  --team-id "SEU_TEAM_ID"
```

Também valide o GitHub CLI:

```bash
gh auth status
```

## 3. Atualizar versão e notas

Antes da build, confirme que `CFBundleShortVersionString` e `CFBundleVersion` correspondem à versão desejada e que o texto de `Releases/notes-X.Y.Z.md` é o texto que será apresentado no **What’s New** e no GitHub Release.

Para uma publicação da versão 2.1.3, por exemplo:

```bash
sed -n '1,200p' Releases/notes-2.1.3.md
```

Faça uma build Debug antes do Release para testar a janela What’s New, os cores e o comportamento do jogo:

```bash
xcodebuild \
  -workspace OpenEmu.xcworkspace \
  -scheme OpenEmu \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build 2>&1 | tee /tmp/openemu-debug-build.log
```

## 4. Gerar o Release

O procedimento automatizado do projeto é:

```bash
cd ~/Documents/GitHub/OpenEmuARM
./Scripts/release.sh X.Y.Z Releases/notes-X.Y.Z.md
```

O script arquiva o app, inclui os cores necessários, chama a notarização, cria `Releases/OpenEmuARM.dmg`, calcula a assinatura EdDSA, atualiza o appcast, cria a branch/tag e prepara um draft no GitHub.

O script exige que a árvore esteja em `main` ou na branch de release esperada. Nunca publique diretamente em `main`; crie ou use a branch de release indicada pelo próprio script.

O script passa `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` diretamente ao `xcodebuild archive`. Portanto, a versão usada no app arquivado é a versão informada no comando, mesmo que o `project.pbxproj` ainda contenha o valor da release anterior.

Se o script parar informando que não encontrou `sign_update`, execute uma build no Xcode e localize o binário correto:

```bash
find ~/Library/Developer/Xcode/DerivedData \
  -path '*/artifacts/sparkle/Sparkle/bin/sign_update' \
  -not -path '*/old_dsa_scripts/*' -print
```

Use somente o `Sparkle/bin/sign_update` moderno, nunca o localizado em `old_dsa_scripts`.

## 5. Conferir o DMG e a assinatura

Depois da geração:

```bash
stat -f '%z bytes' Releases/OpenEmuARM.dmg
"$SIGN_UPDATE" Releases/OpenEmuARM.dmg
```

Se `SIGN_UPDATE` não estiver definido, substitua-o pelo caminho moderno retornado pelo `find`. Guarde no appcast os valores `sparkle:edSignature` e `length` exatamente como foram impressos.

Teste o DMG em outro Mac antes de publicar. Confirme: abertura do app, cores embutidos, What’s New, importação de ROMs, 3DO/Opera, Pokémon Mini e encerramento do PlayStation 2/ARMSX2.

## 6. Revisar e publicar no GitHub

O script cria um draft e uma PR. Revise a PR, o appcast, as notas e o DMG. Depois de testar:

```bash
gh pr list --repo Anhani1206/OpenEmuARM
gh release view vX.Y.Z --repo Anhani1206/OpenEmuARM
```

Após a PR ser mesclada, publique o release draft:

```bash
gh release edit vX.Y.Z --draft=false --repo Anhani1206/OpenEmuARM
```

Se for necessário substituir somente o DMG já publicado:

```bash
gh release upload vX.Y.Z Releases/OpenEmuARM.dmg \
  --repo Anhani1206/OpenEmuARM \
  --clobber
```

Quando o DMG mudar, a assinatura EdDSA e o tamanho também mudam. Nesse caso, atualize o appcast em uma branch separada e abra uma PR contendo somente essa alteração.

## 7. Backup antes de qualquer nova publicação

Crie um backup do estado atual antes de gerar outro Release. O backup desta etapa está em:

```text
Backups/2026-09-29-whats-new-logo/
```

Não inclua `DerivedData`, `.build`, bundles `.app`, DMGs ou executáveis no backup do código-fonte.
