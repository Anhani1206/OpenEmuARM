# Backup — PlayStation fan-disc detection

Date: 2026-09-26

This checkpoint was created before changing PlayStation 1 import detection.
The existing project state was preserved, including unrelated working-tree
changes already present in the repository.

Files relevant to this change before editing:

- `OpenEmu/SystemPlugins/PlayStation/OEPSXSystemController.m`
  - SHA-256: `46429d38837712d4a315bd7cb453eac71421c5fbbbf9e6172303ed147f0b79f7`
- `Releases/notes-2.1.3.md`
  - SHA-256: `9db3609a099cfe234f0a5ace44981b291191195e61d1c9eac24368217d38542a`

The original behavior required the exact `  Licensed  by  ` string at offset
`0x24E0`. The planned change keeps that path and adds a validated fallback for
ISO9660 images containing `CD001` and a valid `SYSTEM.CNF` serial.

The 3DO/Opera `MK2 V12.iso` support is unrelated and is not changed here.
