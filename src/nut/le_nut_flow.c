#include "le_nut_flow.h"

static void push_return(LeNutState *state, uint32_t pointer)
{
    state->return_pointer[state->return_index] = pointer;
    state->return_index = (state->return_index + 1u) & 3u;
}

/* Unwind the four-slot return ring and reset the vacated slot to ROM base. */
static uint32_t pop_return(LeNutState *state)
{
    state->return_index = (state->return_index - 1u) & 3u;
    uint32_t pointer = state->return_pointer[state->return_index];
    state->return_pointer[state->return_index] = LE_ROM_BASE;
    return pointer;
}

int le_nut_flow_execute(LeNutState *state, unsigned opcode,
                       uint32_t next_pointer, uint32_t previous_carry,
                       uint16_t operand, LeNutFlowWatchdog watchdog, void *context,
                       uint32_t *result_pointer)
{
    if (opcode >= 0x400)
        return -1;
    if ((opcode & 3u) == 3u) {
        /* Displacement +1 encodings share the native no-op return and do
         * not service the watchdog, even when their condition matches. */
        if ((opcode >> 3) != 1u &&
            ((opcode >> 2) & 1u) == (previous_carry & 1u)) {
            if ((opcode & 0x200u || opcode < 8u) && !watchdog)
                return -3;
            int displacement = (int)((opcode >> 3) & 63u);
            if (opcode & 0x200u)
                displacement -= 64;
            /* Only zero/backward displacements restart the native watchdog. */
            if (displacement <= 0)
                watchdog(context, state);
            next_pointer += (uint32_t)(2 * (displacement - 1));
        }
    } else if ((opcode & 3u) == 1u) {
        if ((operand & 1u) == previous_carry) {
            int call = !(operand & 2u);
            if (call && state->return_index > 3)
                return -2;
            if (!watchdog)
                return -3;
            next_pointer += 2;
            if (call)
                push_return(state, next_pointer);
            watchdog(context, state);
            /* Native LDRH does not mask diagnostic operand bits above bit 9. */
            next_pointer = LE_ROM_BASE + 2u * ((opcode >> 2) + ((uint32_t)(operand >> 2) << 8));
        } else {
            next_pointer += 2;
        }
    } else {
        switch (opcode) {
        case 0x020:
            (void)pop_return(state);
            break;
        case 0x170:
            if (state->return_index > 3)
                return -2;
            push_return(state, LE_ROM_BASE + 2u * (uint32_t)((state->c >> 12) & 0xffffu));
            break;
        case 0x1b0: {
            uint32_t saved = pop_return(state);
            uint32_t low = (uint32_t)state->c & UINT32_C(0xf0000fff);
            /* Preserve the native base-subtraction error and unmasked OR. */
            low |= ((saved >> 1) - LE_ROM_BASE) << 12;
            state->c = (state->c & UINT64_C(0xffffffff00000000)) | low;
            break;
        }
        case 0x1e0: {
            uint32_t page = ((next_pointer - 2u - LE_ROM_BASE) >> 1) & 0xff00u;
            uint32_t low = (uint32_t)(state->c >> 12) & 0xffu;
            /* Native combines only the low address byte, then doubles the
             * already formed physical pointer. No generic-Nut correction. */
            next_pointer = (LE_ROM_BASE + 2u * (page + low)) << 1;
            break;
        }
        case 0x360:
            if (previous_carry & 1u)
                next_pointer = pop_return(state);
            break;
        case 0x3a0:
            if (!(previous_carry & 1u))
                next_pointer = pop_return(state);
            break;
        case 0x3e0:
            next_pointer = pop_return(state);
            break;
        default:
            return -1;
        }
    }
    *result_pointer = next_pointer;
    return 0;
}
