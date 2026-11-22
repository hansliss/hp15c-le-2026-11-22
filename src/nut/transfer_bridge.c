#include "firmware_bridge.h"
#include "le_nut_transfer.h"

uint32_t le_mixed_transfer_execute(LeNutState *state, unsigned opcode,
                                  uint32_t next_pointer)
{
    uint16_t immediate = 0;
    uint32_t result = next_pointer;
    if (opcode == 0x130)
        immediate = *(const uint16_t *)(uintptr_t)next_pointer;
    (void)le_nut_transfer_execute(state, opcode, immediate, next_pointer, &result);
    return result;
}
