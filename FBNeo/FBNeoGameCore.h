// Copyright (c) 2026, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// the copyright notice and this permission notice remain in all copies.

#import <OpenEmuBase/OELibretroCoreTranslator.h>

/// OpenEmu-owned host for the bundled FBNeo libretro engine.
///
/// This is intentionally a separate plugin class instead of a RetroArch stub:
/// the FBNeo dylib is shipped inside FBNeo.oecoreplugin and is loaded from the
/// bundle by OELibretroCoreTranslator.
@interface FBNeoGameCore : OELibretroCoreTranslator
@end
