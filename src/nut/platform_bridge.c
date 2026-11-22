#include "firmware_bridge.h"
#include "le_nut_platform.h"

#ifndef LE_MIXED_QUOTA
#error "Select the display quota mode"
#endif
#ifndef LE_MIXED_BLINK_LEGACY
#error "Select the blink behavior"
#endif

#define COUNTER (*(volatile uint32_t *)(uintptr_t)0x200010)

static void render(void *context, LeNutState *state, LeDisplayPolicy *policy)
{
    (void)context;
    COUNTER = policy->counter;
    le_mixed_lcd_update(state);
    policy->counter = COUNTER;
}

static uint32_t read_word(void *context, uint32_t address)
{
    LeDisplayPolicy *policy = context;
    COUNTER = policy->counter;
    return *(volatile uint32_t *)(uintptr_t)address;
}

static void set_clock(void *context, uint32_t argument)
{
    LeDisplayPolicy *policy = context;
    COUNTER = policy->counter;
    ((void (*)(uint32_t))(uintptr_t)0x10fb7c)(argument);
    policy->counter = COUNTER;
}

static void wait(void *context, uint32_t count)
{
    LeDisplayPolicy *policy = context;
    COUNTER = policy->counter;
    ((void (*)(uint32_t))(uintptr_t)0x111944)(count);
    policy->counter = COUNTER;
}

uint64_t le_mixed_platform_execute(LeNutState *state, unsigned opcode, uint32_t next)
{
    uint32_t result = next;
    if (opcode == 0x060) {
        int control = le_nut_platform_execute(LE_NUT_PLATFORM_APRIL, state, opcode,
            0, next, 0, LE_DISPLAY_BLINK_ENABLE, 0, &result);
        return ((uint64_t)(unsigned)control << 32) | result;
    }
    uint16_t word = opcode == 0x2e0 ? *(const uint16_t *)(uintptr_t)next : 0;
    LeDisplayPolicy policy = {LE_MIXED_QUOTA, COUNTER};
    LeNutPlatformIo io = {&policy, render, read_word, set_clock, wait};
    int control = le_nut_platform_execute(LE_NUT_PLATFORM_APRIL, state, opcode,
        word, next, &policy, LE_MIXED_BLINK_LEGACY ? LE_DISPLAY_BLINK_LEGACY_TOGGLE
                                               : LE_DISPLAY_BLINK_ENABLE,
        &io, &result);
    COUNTER = policy.counter;
    return ((uint64_t)(unsigned)control << 32) | result;
}
