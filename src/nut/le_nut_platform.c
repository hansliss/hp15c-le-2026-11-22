#include "le_nut_platform.h"

typedef struct {
    LeNutState *state;
    const LeNutPlatformIo *io;
} RenderContext;

static void render(void *context, LeDisplayPolicy *policy, LeDisplayFlags *flags)
{
    RenderContext *bridge = context;
    bridge->state->display_off = flags->off;
    bridge->state->display_blink = flags->blink;
    bridge->io->render(bridge->io->context, bridge->state, policy);
    flags->off = bridge->state->display_off;
    flags->blink = bridge->state->display_blink;
}

/* Native signed division rounds toward zero. Use only unsigned arithmetic,
 * including for INT_MIN and negative diagnostic words. */
static uint32_t quarter(uint32_t word)
{
    return word & UINT32_C(0x80000000) ? 0u - ((0u - word) / 4u) : word / 4u;
}

int le_nut_platform_execute(LeNutPlatformVariant variant, LeNutState *state,
    unsigned opcode, uint16_t next_word, uint32_t next_pointer,
    LeDisplayPolicy *policy, LeDisplayBlinkMode blink_mode,
    const LeNutPlatformIo *io, uint32_t *result_pointer)
{
    if (opcode == 0x060) {
        *result_pointer = next_pointer;
        return 1;
    }
    if (opcode != 0x018 && opcode != 0x030 && opcode != 0x2e0 && opcode != 0x320)
        return -1;
    if (!policy || !io || !io->render ||
        (opcode == 0x018 && (!io->read_word || !io->set_clock || !io->wait)))
        return -2;

    RenderContext bridge = {state, io};
    LeDisplayFlags flags = {state->display_off, state->display_blink};
    int fused = le_display_event_with_blink(policy, &flags, opcode, next_word,
                                           blink_mode, render, &bridge);
    state->display_off = flags.off;
    state->display_blink = flags.blink;
    if (fused)
        next_pointer += 2;
    if (opcode == 0x018) {
        uint32_t requested = variant == LE_NUT_PLATFORM_2009 ? 0x200888 : 0x2008a0;
        uint32_t current = variant == LE_NUT_PLATFORM_2009 ? 0x200884 : 0x20089c;
        io->set_clock(io->context, io->read_word(io->context, requested));
        io->wait(io->context, quarter(io->read_word(io->context, current)));
        io->set_clock(io->context, UINT32_C(0x02255100));
        state->c &= ~UINT64_C(0xfff);
    }
    *result_pointer = next_pointer;
    return 0;
}
