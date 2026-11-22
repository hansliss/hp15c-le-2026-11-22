#include "le_nut_pointer.h"

static const int8_t pointer_digit[16] = {
    3, 4, 5, 10, 8, 6, 11, -1, 2, 9, 7, 13, 1, 12, 0, -1
};

/* The native 64-bit helper uses the low byte of the shift count. */
static uint64_t shift_word(uint64_t word, unsigned shift)
{
    shift &= 0xffu;
    return shift < 64 ? word << shift : 0;
}

void le_nut_refresh_fields(LeNutState *state, unsigned selected)
{
    const uint64_t word_mask = UINT64_C(0x00ffffffffffffff);
    unsigned shift = (uint8_t)(selected * 4);
    state->selected_digit_shift = (uint8_t)shift;
    state->p_digit_shift = (uint8_t)(state->p * 4);
    state->selected_digit_mask = shift_word(15, shift);
    state->through_selected_mask = word_mask & ~shift_word(word_mask, shift + 4);
    state->pq_mask = shift_word(UINT64_MAX, state->p * 4);
    if (state->q >= state->p)
        state->pq_mask &= ~shift_word(UINT64_MAX, (state->q + 1) * 4);
    state->pq_mask &= word_mask;
}

int le_nut_pointer_execute(LeNutState *state, unsigned opcode,
                          uint32_t next_pointer, uint32_t *result_pointer)
{
    unsigned family = opcode & 0x3f;
    int digit = opcode < 0x400 ? pointer_digit[opcode >> 6] : -1;
    int immediate = digit >= 0 && (family == 0x14 || family == 0x1c);
    if (!immediate && opcode != 0xa0 && opcode != 0xe0 && opcode != 0x120
        && opcode != 0x3d4 && opcode != 0x3dc)
        return -1;
    if (state->p > 13 || state->q > 13
        || (state->selected_pointer != LE_BACKUP_BASE + 0x28
            && state->selected_pointer != LE_BACKUP_BASE + 0x29))
        return -2;
    uint8_t *selected = state->selected_pointer == LE_BACKUP_BASE + 0x28
        ? &state->p : &state->q;
    if (immediate && family == 0x14) {
        next_pointer += *selected == (unsigned)digit;
    } else if (opcode == 0x120) {
        /* Native ADD r0,P followed by CMP r0,Q and MOV r0,#0/#1. */
        next_pointer = (uint32_t)(next_pointer + state->p) == state->q;
    } else {
        if (immediate) {
            *selected = (uint8_t)digit;
        } else if (opcode == 0x3d4) {
            *selected = *selected == 0 ? 13 : (uint8_t)(*selected - 1);
        } else if (opcode == 0x3dc) {
            *selected = *selected == 13 ? 0 : (uint8_t)(*selected + 1);
        } else {
            state->selected_pointer = LE_BACKUP_BASE + (opcode == 0xa0 ? 0x28 : 0x29);
            selected = opcode == 0xa0 ? &state->p : &state->q;
        }
        le_nut_refresh_fields(state, *selected);
    }
    *result_pointer = next_pointer;
    return 0;
}
