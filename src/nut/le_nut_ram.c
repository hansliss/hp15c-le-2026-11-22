#include "le_nut_ram.h"

static const uint8_t page_map[16] = {
    0, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
};

int le_nut_ram_execute(LeNutRamVariant variant, LeNutState *state, unsigned opcode,
                       LeNutRamDisplay display, void *context)
{
    unsigned reg = state->ram_register;
    unsigned page = state->ram_page;

    if (opcode <= 0x3e4 && (opcode & 0x3f) == 0x24) {
        state->ram_page = page_map[opcode >> 6];
        return 0;
    }
    if (opcode == 0x270) {
        state->ram_page = page_map[(state->c >> 4) & 15];
        state->ram_register = state->c & 15;
        return 0;
    }

    const unsigned immediate_write = opcode <= 0x3e8 && (opcode & 0x3f) == 0x28;
    const unsigned read = opcode <= 0x3f8 && (opcode & 0x3f) == 0x38;
    if (!immediate_write && !read && opcode != 0x2f0 && opcode != 0x2b0) {
        return -1;
    }
    if (immediate_write || (read && opcode != 0x038)) {
        reg = opcode >> 6;
    }
    if (page >= 15 || (opcode != 0x2b0 && reg >= 16)) {
        return -2;
    }
    if (opcode == 0x2b0) {
        for (unsigned index = 0; index < 16; ++index) {
            state->ram_candidate[page * 16 + index] = 0;
        }
        return 0;
    }
    if (immediate_write || (read && opcode != 0x038)) {
        state->ram_register = reg;
    }
    uint64_t *slot = &state->ram_candidate[page * 16 + reg];
    if (read) {
        state->c = *slot;
    } else if (page != 0 || reg != 8) {
        *slot = state->c;
        if (immediate_write && ((variant == LE_NUT_RAM_2009 && (reg == 9 || reg == 10))
                                || (variant == LE_NUT_RAM_APRIL && page == 0 && reg == 9))) {
            display(context, state);
        }
    }
    return 0;
}
