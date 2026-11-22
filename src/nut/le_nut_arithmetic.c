#include "le_nut_arithmetic.h"
#include "le_nut_decimal.h"

static uint64_t arithmetic_mask(const LeNutState *state, unsigned field)
{
    switch (field) {
    case 0: return state->selected_digit_mask;
    case 1: return UINT64_C(0xfff);
    case 2: return state->through_selected_mask;
    case 3: return UINT64_C(0x00ffffffffffffff);
    case 4: return state->pq_mask;
    case 5: return UINT64_C(0xf00);
    case 6: return UINT64_C(0x000ffffffffff000);
    default: return UINT64_C(0x00f0000000000000);
    }
}

/* Place the increment at the least-significant digit of the selected field. */
static uint64_t field_one(const LeNutState *state, unsigned field)
{
    unsigned shift;
    switch (field) {
    case 0: shift = state->selected_digit_shift; break;
    case 4: shift = state->p_digit_shift; break;
    case 5: shift = 8; break;
    case 6: shift = 12; break;
    case 7: shift = 52; break;
    default: shift = 0; break;
    }
    return shift < 64 ? UINT64_C(1) << shift : 0;
}

int le_nut_arithmetic_execute(LeNutState *state, unsigned opcode,
                             uint32_t next_pointer, uint32_t *result_pointer)
{
    unsigned operation = opcode >> 5;
    if (opcode >= 0x400 || (opcode & 3) != 2 || operation < 9 || operation > 21)
        return -1;
    unsigned field = (opcode >> 2) & 7;
    uint64_t mask = arithmetic_mask(state, field);
    uint64_t one = field_one(state, field);
    uint64_t *destination = operation <= 14 ? &state->a : &state->c;
    uint64_t left, right;
    int subtract = 0;
    switch (operation) {
    case 9: left = state->a; right = state->b; break;
    case 10: left = state->a; right = state->c; break;
    case 11: left = state->a; right = one; break;
    case 12: left = state->a; right = state->b; subtract = 1; break;
    case 13: left = state->a; right = one; subtract = 1; break;
    case 14: left = state->a; right = state->c; subtract = 1; break;
    case 15: left = state->c; right = state->c; break;
    case 16: left = state->c; right = state->a; break;
    case 17: left = state->c; right = one; break;
    case 18: left = state->a; right = state->c; subtract = 1; break;
    case 19: left = state->c; right = one; subtract = 1; break;
    case 20: left = 0; right = state->c; subtract = 1; break;
    default:
        /* Native C=-C-1 performs both masked subtractions and then returns
         * carry=1 unconditionally, discarding the helper borrow results. */
        (void)le_nut_masked_subtract(0, state->c, destination, mask, state->hex_mode);
        (void)le_nut_masked_subtract(state->c, one, destination, mask, state->hex_mode);
        *result_pointer = next_pointer + 1;
        return 0;
    }
    unsigned carry = subtract
        ? le_nut_masked_subtract(left, right, destination, mask, state->hex_mode)
        : le_nut_masked_add(left, right, destination, mask, state->hex_mode);
    *result_pointer = next_pointer + carry;
    return 0;
}
