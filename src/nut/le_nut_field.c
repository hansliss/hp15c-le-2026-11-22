#include "le_nut_field.h"

#define WORD_MASK UINT64_C(0x00ffffffffffffff)

static const int8_t rotation_digit[16] = {
    3, 4, 5, 10, 8, 6, 11, -1, 2, 9, 7, 13, 1, 12, 0, -1
};

static uint64_t field_mask(const LeNutState *state, unsigned field)
{
    switch (field) {
    case 0: return state->selected_digit_mask;
    case 1: return UINT64_C(0xfff);
    case 2: return state->through_selected_mask;
    case 3: return WORD_MASK;
    case 4: return state->pq_mask;
    case 5: return UINT64_C(0xf00);
    case 6: return UINT64_C(0x000ffffffffff000);
    default: return UINT64_C(0x00f0000000000000);
    }
}

static uint64_t shift_field(uint64_t value, uint64_t mask,
                            unsigned field, int left)
{
    uint64_t outside = value & ~mask;
    if (field == 0 || field == 5 || field == 7)
        return outside; /* A one-digit shift clears the field. */
    if (field == 3)
        return left ? (value << 4) & WORD_MASK : value >> 4;
    if (field == 2) {
        /* Native WP paths differ when a deliberately stale mask has holes. */
        return outside | (left ? (value << 4) & mask : (value & mask) >> 4);
    }
    return outside | (left ? ((value & mask) << 4) & mask
                           : ((value & mask) >> 4) & mask);
}

int le_nut_field_execute(LeNutState *state, unsigned opcode,
                        uint32_t next_pointer, uint32_t *result_pointer)
{
    if (opcode >= 0x400)
        return -1;
    if ((opcode & 0x3f) == 0x3c && rotation_digit[opcode >> 6] >= 0) {
        unsigned shift = (unsigned)rotation_digit[opcode >> 6] * 4;
        uint64_t value = state->c;
        state->c = shift == 0 ? value & WORD_MASK
            : ((value >> shift) | (value << (56-shift))) & WORD_MASK;
    } else if ((opcode & 3) == 2) {
        unsigned operation = opcode >> 5;
        unsigned field = (opcode >> 2) & 7;
        uint64_t mask = field_mask(state, field);
        uint64_t temporary;
        uint64_t *destination;
        switch (operation) {
        case 0: state->a &= ~mask; break;
        case 1: state->b &= ~mask; break;
        case 2: state->c &= ~mask; break;
        case 3:
            temporary = (state->a ^ state->b) & mask;
            state->a ^= temporary;
            state->b ^= temporary;
            break;
        case 4: state->b = (state->b & ~mask) | (state->a & mask); break;
        case 5:
            temporary = (state->a ^ state->c) & mask;
            state->a ^= temporary;
            state->c ^= temporary;
            break;
        case 6: state->c = (state->c & ~mask) | (state->b & mask); break;
        case 7:
            temporary = (state->b ^ state->c) & mask;
            state->b ^= temporary;
            state->c ^= temporary;
            break;
        case 8: state->a = (state->a & ~mask) | (state->c & mask); break;
        case 28:
        case 29:
        case 30:
        case 31:
            destination = operation == 29 ? &state->b
                : operation == 30 ? &state->c : &state->a;
            *destination = shift_field(*destination, mask, field, operation == 31);
            break;
        default:
            return -1;
        }
    } else {
        return -1;
    }
    *result_pointer = next_pointer;
    return 0;
}
