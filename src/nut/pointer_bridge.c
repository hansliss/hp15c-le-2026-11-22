#include "firmware_bridge.h"
#include "le_nut_pointer.h"

uint32_t le_mixed_pointer_execute(LeNutState *state, unsigned opcode,
                                 uint32_t next_pointer)
{
    uint32_t result = next_pointer;
    (void)le_nut_pointer_execute(state, opcode, next_pointer, &result);
    return result;
}
