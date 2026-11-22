#include "le_nut_control.h"

static const int8_t status_bit[16] = {
    3, 4, 5, 10, 8, 6, 11, -1, 2, 9, 7, 13, 1, 12, 0, -1
};

int le_nut_control_execute(LeNutState *state, unsigned opcode,
                           uint32_t next_pointer, uint32_t *result_pointer)
{
    unsigned family = opcode & 0x3f;
    if (opcode < 0x400 && (family == 4 || family == 8 || family == 12)
        && status_bit[opcode >> 6] >= 0) {
        unsigned bit = (unsigned)status_bit[opcode >> 6];
        uint16_t mask = (uint16_t)(1u << bit);
        if (family == 4)
            state->status &= (uint16_t)~mask;
        else if (family == 8)
            state->status |= mask;
        else
            next_pointer += (state->status >> bit) & 1u;
    } else {
        switch (opcode) {
        case 0x358:
            /* LE uses STRH of C's low byte, clearing all higher status bits. */
            state->status = (uint8_t)state->c;
            break;
        case 0x398:
            /* Exact native OR semantics, not generic Nut low-byte insertion. */
            state->c = (state->c & ~UINT64_C(0xff)) | state->status;
            break;
        case 0x3d8: {
            uint8_t old_status = (uint8_t)state->status;
            state->status = (state->status & 0xff00u) | (uint8_t)state->c;
            state->c = (state->c & ~UINT64_C(0xff)) | old_status;
            break;
        }
        case 0x3c4:
            state->status &= 0xff00u;
            break;
        case 0x260:
            state->hex_mode = 1;
            break;
        case 0x2a0:
            state->hex_mode = 0;
            break;
        default:
            return -1;
        }
    }
    *result_pointer = next_pointer;
    return 0;
}
