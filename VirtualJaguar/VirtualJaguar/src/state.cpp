//
// state.cpp: VJ machine state save/load support
//
// by James Hammons
// (C) 2010 Underground Software
//
// JLH = James Hammons <jlhamm@acm.org>
//
// Who  When        What
// ---  ----------  -------------------------------------------------------------
// JLH  01/16/2010  Created this log ;-)
//

#include "state.h"
#include "jaguar.h"
#include "memory.h"
#include "m68000/m68kinterface.h"

#include <cstring>

namespace {
constexpr uint32_t kStateMagic = 0x564A5354; // "VJST"
constexpr uint32_t kStateVersion = 1;
constexpr size_t kMemorySize = 0xF20000;
constexpr size_t kRegisterCount = M68K_REG_A7 + 1;

struct StateHeader {
	uint32_t magic;
	uint32_t version;
	uint32_t memorySize;
	uint32_t registerCount;
};

struct StateTail {
	uint32_t romCRC32;
	uint32_t romSize;
	uint32_t runAddress;
	uint32_t bpmAddress;
	uint32_t gRemain;
	uint32_t dRemain;
	uint16_t asistat;
	uint16_t lrxd;
	uint16_t rrxd;
	uint8_t sstat;
	uint8_t cartInserted;
	uint8_t bpmIsActive;
	uint8_t reserved;
};

constexpr size_t StateSize()
{
	return sizeof(StateHeader) + kMemorySize + (kRegisterCount * sizeof(uint32_t)) + sizeof(StateTail);
}
}

bool SaveState(void)
{
	return false;
}

bool LoadState(void)
{
	return false;
}

size_t JaguarStateSize(void)
{
	return StateSize();
}

bool JaguarStateSave(void *buffer, size_t bufferSize)
{
	if (!buffer || bufferSize < StateSize()) return false;

	uint8_t *cursor = static_cast<uint8_t *>(buffer);
	const StateHeader header = { kStateMagic, kStateVersion, (uint32_t)kMemorySize, (uint32_t)kRegisterCount };
	memcpy(cursor, &header, sizeof(header));
	cursor += sizeof(header);
	memcpy(cursor, jagMemSpace, kMemorySize);
	cursor += kMemorySize;

	for (size_t i = 0; i < kRegisterCount; ++i) {
		const uint32_t value = m68k_get_reg(nullptr, (m68k_register_t)i);
		memcpy(cursor + (i * sizeof(uint32_t)), &value, sizeof(value));
	}
	cursor += kRegisterCount * sizeof(uint32_t);

	const StateTail tail = {
		jaguarMainROMCRC32, jaguarROMSize, jaguarRunAddress, bpmAddress1,
		g_remain, d_remain, asistat, lrxd,
		rrxd, sstat, (uint8_t)(jaguarCartInserted ? 1 : 0),
		(uint8_t)(bpmActive ? 1 : 0), 0
	};
	memcpy(cursor, &tail, sizeof(tail));
	return true;
}

bool JaguarStateLoad(const void *buffer, size_t bufferSize)
{
	if (!buffer || bufferSize < StateSize()) return false;

	const uint8_t *cursor = static_cast<const uint8_t *>(buffer);
	StateHeader header = {};
	memcpy(&header, cursor, sizeof(header));
	if (header.magic != kStateMagic || header.version != kStateVersion ||
		header.memorySize != kMemorySize || header.registerCount != kRegisterCount)
		return false;
	cursor += sizeof(header);
	memcpy(jagMemSpace, cursor, kMemorySize);
	cursor += kMemorySize;

	for (size_t i = 0; i < kRegisterCount; ++i) {
		uint32_t value = 0;
		memcpy(&value, cursor + (i * sizeof(uint32_t)), sizeof(value));
		m68k_set_reg((m68k_register_t)i, value);
	}
	cursor += kRegisterCount * sizeof(uint32_t);

	StateTail tail = {};
	memcpy(&tail, cursor, sizeof(tail));
	jaguarMainROMCRC32 = tail.romCRC32;
	jaguarROMSize = tail.romSize;
	jaguarRunAddress = tail.runAddress;
	bpmAddress1 = tail.bpmAddress;
	bpmActive = tail.bpmIsActive != 0;
	g_remain = tail.gRemain;
	d_remain = tail.dRemain;
	asistat = tail.asistat;
	lrxd = tail.lrxd;
	rrxd = tail.rrxd;
	sstat = tail.sstat;
	jaguarCartInserted = tail.cartInserted != 0;
	return true;
}
