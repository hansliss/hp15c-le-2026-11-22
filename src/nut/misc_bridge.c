#include "firmware_bridge.h"
#include "le_nut_misc.h"

static uint16_t read_rom(void *context, uint16_t address)
{
    (void)context;
    return *(const uint16_t *)(uintptr_t)(LE_ROM_BASE + 2u * address);
}

uint32_t le_mixed_misc_execute(LeNutState *state, unsigned opcode,
                              uint32_t next_pointer)
{
    uint32_t result = next_pointer;
    (void)le_nut_misc_execute(LE_NUT_MISC_APRIL15, state, opcode, next_pointer,
                            read_rom, 0, &result);
    return result;
}
