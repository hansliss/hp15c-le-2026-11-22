#include "le_lcd.h"
#include "le_display.h"

#define SUPC_MR UINT32_C(0xfffffd18)
#define SLCDC_DR UINT32_C(0xfffb400c)
#define LCD_USER_BASE UINT32_C(0xfffb4200)

typedef struct {
    const LeLcdIo *io;
} SegmentIoContext;

static uint32_t read_segment_word(void *context, unsigned index)
{
    const SegmentIoContext *segment = context;
    const LeLcdIo *io = segment->io;
    return io->read32(io->context, LCD_USER_BASE + 4 * index);
}

static void write_segment_word(void *context, unsigned index, uint32_t value)
{
    const SegmentIoContext *segment = context;
    const LeLcdIo *io = segment->io;
    io->write32(io->context, LCD_USER_BASE + 4 * index, value);
}

static void clear_user_words(const LeLcdIo *io)
{
    /* Preserve the ARM store order, including the four odd words. */
    for (unsigned index = 8; index != 0; --index) {
        io->write32(io->context, LCD_USER_BASE + 4 * (index - 1), 0);
    }
}

void le_lcd_update(LeLcdVariant variant, LeLcdState *state, const LeLcdIo *io)
{
    const unsigned supply_off = (io->read32(io->context, SUPC_MR) & 0x30) == 0;
    const unsigned previous_dr_nonzero = io->read32(io->context, SLCDC_DR) != 0;

    if (state->mode != 0) {
        state->flags.blink = 0;
    }
    if (supply_off != state->flags.off) {
        const unsigned disable = variant == LE_LCD_2009
            ? state->flags.off != 0
            : ((state->mode ^ 1u) & state->flags.off) != 0;

        if (disable) {
            io->disable(io->context);
            clear_user_words(io);
        } else {
            /* Only the first 64-bit cache value is invalidated here. */
            state->cache[0] = UINT64_MAX;
            io->enable(io->context, 0);
        }
    }
    if (state->flags.off != 0) {
        return;
    }

    /* Use the entry DR snapshot, even if enable or a wait changes DR. */
    if (state->mode == 0 && state->flags.blink != previous_dr_nonzero) {
        io->write32(io->context, SLCDC_DR, 0);
        io->wait_frames(io->context, 1);
    }

    const uint64_t shifted_b0 = state->source_b0 >> 6;
    const uint64_t shifted_b8 = state->source_b8 >> 6;

    if (state->cache[0] != shifted_b0 || state->cache[1] != shifted_b8) {
        SegmentIoContext segment = {io};
        const LeDisplayWordIo words = {
            &segment, read_segment_word, write_segment_word
        };
        state->cache[0] = shifted_b0;
        state->cache[1] = shifted_b8;
        le_display_map_io(state->source_b0, state->source_b8, &words);
    }

    uint32_t battery_word = io->read32(io->context, LCD_USER_BASE + 6 * 4);
    if (state->battery != 0) {
        battery_word |= UINT32_C(1);
    } else {
        battery_word &= ~UINT32_C(1);
    }
    io->write32(io->context, LCD_USER_BASE + 6 * 4, battery_word);

    if (state->mode == 0 && ((previous_dr_nonzero ^ 1u) & state->flags.blink)) {
        io->wait_frames(io->context, 2);
        io->write32(io->context, SLCDC_DR, 0x1906);
        io->wait_frames(io->context, 1);
        clear_user_words(io);
        io->write32(io->context, SLCDC_DR, 0x1907);
    }
}
