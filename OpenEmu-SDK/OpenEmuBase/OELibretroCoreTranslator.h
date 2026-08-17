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

#import <OpenEmuBase/OEGameCore.h>

/// Version stamp for the OE→libretro translator code that ships inside this
/// binary. Bump this in the same commit as any behavioral change to
/// OELibretroCoreTranslator.{h,m}. On every launch, OpenEmu compares this
/// value to the OEBridgeVersion key inside each installed RetroArch stub
/// and refreshes any stub whose version is missing or stale, so users
/// pick up bridge fixes without having to re-add cores.
extern NSString * _Nonnull const OELibretroBridgeVersion;

@interface OELibretroCoreTranslator : OEGameCore <OELibretroInputReceiver>
/// Extracts the internal 'library_version' from a Libretro dylib without full initialization.
+ (nullable NSString *)libraryVersionForCoreAtURL:(nonnull NSURL *)url;
@end
