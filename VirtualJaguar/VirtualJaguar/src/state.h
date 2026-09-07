//
// state.h: Machine state save/load support
//
// by James L. Hammons
//

#ifndef __STATE_H__
#define __STATE_H__

#include <stddef.h>

bool SaveState(void);
bool LoadState(void);

// OpenEmu save-state bridge. The old standalone state entry points above are
// kept for compatibility with the original Jaguar sources.
size_t JaguarStateSize(void);
bool JaguarStateSave(void *buffer, size_t bufferSize);
bool JaguarStateLoad(const void *buffer, size_t bufferSize);

#endif	// __STATE_H__
