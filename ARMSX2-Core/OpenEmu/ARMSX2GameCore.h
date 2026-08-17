/*
 Copyright (c) 2026

 Minimal OpenEmu wrapper for the ARMSX2 libretro core.
 */

#import <OpenEmuBase/OEGameCore.h>
#import "OEPS2SystemResponderClient.h"

OE_EXPORTED_CLASS
@interface ARMSX2GameCore : OEGameCore <OEPS2SystemResponderClient>
@end
