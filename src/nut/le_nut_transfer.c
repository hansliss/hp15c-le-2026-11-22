#include "le_nut_transfer.h"
#include "le_nut_pointer.h"

int le_nut_transfer_execute(LeNutState *state, unsigned opcode,
                           uint16_t immediate, uint32_t next_pointer,
                           uint32_t *result_pointer)
{
    uint64_t temporary;
    int load_digit = opcode < 0x400 && (opcode & 0x3f) == 0x10;
    int transfer_g = opcode == 0x58 || opcode == 0x98 || opcode == 0xd8;
    unsigned selected = 0;

    if (load_digit || transfer_g) {
        if (state->selected_pointer == LE_BACKUP_BASE + 0x28)
            selected = state->p;
        else if (state->selected_pointer == LE_BACKUP_BASE + 0x29)
            selected = state->q;
        else
            return -2;
        if (selected > 13)
            return -2;
    }
    if (load_digit) {
        if (state->p > 13 || state->q > 13 || state->selected_digit_shift > 63)
            return -2;
        /* Native ADD, rather than OR, matters when the cache is stale. */
        state->c = (state->c & ~state->selected_digit_mask)
            + ((uint64_t)(opcode >> 6) << state->selected_digit_shift);
        return le_nut_pointer_execute(state, 0x3d4, next_pointer, result_pointer);
    }
    if (transfer_g) {
        unsigned shift = selected * 4;
        uint8_t old_c = (uint8_t)(state->c >> shift);
        if (opcode != 0x58) {
            state->c = (state->c & ~(UINT64_C(255) << shift))
                | ((uint64_t)state->g << shift);
        }
        if (opcode != 0x98)
            state->g = old_c;
    } else {
        switch (opcode) {
        case 0x070:
            state->n = state->c;
            break;
        case 0x0b0:
            state->c = state->n;
            break;
        case 0x0f0:
            temporary = state->c;
            state->c = state->n;
            state->n = temporary;
            break;
        case 0x158:
            state->m = state->c;
            break;
        case 0x198:
            state->c = state->m;
            break;
        case 0x1d8:
            temporary = state->c;
            state->c = state->m;
            state->m = temporary;
            break;
        case 0x130:
            /* Native OR uses all 16 operand bits, although only 12 C bits
             * are cleared. Diagnostic high operand bits can set C[15:12]. */
            state->c = (state->c & ~UINT64_C(0xfff)) | immediate;
            next_pointer += 2;
            break;
        default:
            return -1;
        }
    }
    *result_pointer = next_pointer;
    return 0;
}
