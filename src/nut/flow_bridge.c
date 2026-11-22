#include "firmware_bridge.h"
#include "le_nut_flow.h"

static void restart_watchdog(void *context, LeNutState *state)
{
    (void)context;
    (void)state;
    *(volatile uint32_t *)(uintptr_t)LE_NUT_WATCHDOG_ADDRESS = LE_NUT_WATCHDOG_RESTART;
}

uint32_t le_mixed_flow_execute(LeNutState *state, unsigned opcode,
                               uint32_t next_pointer, uint32_t previous_carry)
{
    uint16_t operand = 0;
    uint32_t result = next_pointer;
    if ((opcode & 3u) == 1u)
        operand = *(const uint16_t *)(uintptr_t)next_pointer;
    (void)le_nut_flow_execute(state, opcode, next_pointer, previous_carry, operand,
                             restart_watchdog, 0, &result);
    return result;
}
