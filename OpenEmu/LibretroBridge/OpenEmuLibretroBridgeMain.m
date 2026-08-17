// Copyright (c) 2026, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// This file is the sole compiled source for the OpenEmuLibretroBridge.oecoreplugin
// target. The bundle has no entry point of its own — it exists to ship the
// OpenEmuBase translator code (linked in via the framework) as a valid loadable
// `.oecoreplugin` bundle. AppDelegate.refreshStaleRetroArchStubs() copies this
// bundle's executable into installed RetroArch stubs at launch so bridge fixes
// flow through automatically. See AGENTS.md → "Libretro Bridge Version Bumps".

#import <Foundation/Foundation.h>
#import <OpenEmuBase/OELibretroCoreTranslator.h>

// Touch the symbol so the linker keeps OELibretroCoreTranslator + the bridge
// version constant in the bundle binary even though no code path inside this
// translation unit calls them at runtime. Without a reference, dead-code
// stripping at link time may drop the class.
__attribute__((used))
static void OpenEmuLibretroBridgeKeepSymbols(void) {
    (void)[OELibretroCoreTranslator class];
    (void)OELibretroBridgeVersion;
}
