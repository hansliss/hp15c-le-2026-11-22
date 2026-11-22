#include "le_nut_compare.h"

static uint64_t comparison_mask(const LeNutState *state, unsigned field)
{
    switch (field) {
    case 0: return state->selected_digit_mask;
    case 1: return UINT64_C(0xfff);
    case 2: return state->through_selected_mask;
    case 3: return UINT64_MAX; /* Native W tests include the diagnostic byte. */
    case 4: return state->pq_mask;
    case 5: return UINT64_C(0xf00);
    case 6: return UINT64_C(0x000ffffffffff000);
    default: return UINT64_C(0x00f0000000000000);
    }
}

int le_nut_compare_execute(const LeNutState *state, unsigned opcode,
                          uint32_t next_pointer, uint32_t *result_pointer)
{
    unsigned operation = opcode >> 5;
    if (opcode >= 0x400 || (opcode & 3) != 2 || operation < 22 || operation > 27)
        return -1;
    uint64_t mask = comparison_mask(state, (opcode >> 2) & 7);
    unsigned result;
    switch (operation) {
    case 22: result = (state->b & mask) != 0; break;
    case 23: result = (state->c & mask) != 0; break;
    case 24: result = (state->a & mask) < (state->c & mask); break;
    case 25: result = (state->a & mask) < (state->b & mask); break;
    case 26: result = (state->a & mask) != 0; break;
    default: result = ((state->a ^ state->c) & mask) != 0; break;
    }
    *result_pointer = next_pointer + result;
    return 0;
}
