#include "le_nut_misc.h"

/* The extension uses its own 14-digit addition loop, distinct from the
 * compiler packed-decimal helper used by ordinary arithmetic. Retain its
 * full intermediate values and threshold comparisons for malformed BCD. */
static uint64_t extension_decimal_add(uint64_t left, uint64_t right)
{
    uint64_t sum = 0, mask = 15, threshold = 9, correction = 6;
    for (unsigned digit = 0; digit < 14; ++digit) {
        sum += (left & mask) + (right & mask);
        if (sum > threshold)
            sum += correction;
        mask <<= 4;
        correction <<= 4;
        threshold = (threshold << 4) + 15;
    }
    return sum;
}

int le_nut_misc_execute(LeNutMiscVariant variant, LeNutState *state,
                       unsigned opcode, uint32_t next_pointer,
                       LeNutMiscReadRom read_rom, void *context,
                       uint32_t *result_pointer)
{
    switch (opcode) {
    case 0x1a0:
        state->a = state->b = state->c = 0;
        break;
    case 0x370:
        state->c |= state->a; /* All 64 slot bits, including diagnostic byte. */
        break;
    case 0x3b0:
        state->c &= state->a;
        break;
    case 0x330: {
        if (!read_rom)
            return -2;
        uint32_t old_low = (uint32_t)state->c;
        uint16_t word = read_rom(context, (uint16_t)(old_low >> 12));
        uint32_t low = (old_low & UINT32_C(0xfffff000)) | word;
        state->c = (state->c & UINT64_C(0xffffffff00000000)) | low;
        break;
    }
    case 0x3ac:
        if (variant == LE_NUT_MISC_APRIL15) {
            const uint64_t mask = UINT64_C(0x000ffffffffff000);
            uint64_t value = state->a & mask;
            value = state->hex_mode ? value + 0x1000u
                                   : extension_decimal_add(value, 0x1000u);
            state->a = (state->a & ~mask) | (value & mask);
            next_pointer += (value & ~mask) != 0;
        }
        break;
    default:
        switch (opcode) {
        case 0x000:
        case 0x02c:
        case 0x034:
        case 0x040:
        case 0x06c:
        case 0x074:
        case 0x080:
        case 0x0ac:
        case 0x0b4:
        case 0x0c0:
        case 0x0ec:
        case 0x0f4:
        case 0x100:
        case 0x12c:
        case 0x134:
        case 0x140:
        case 0x160:
        case 0x16c:
        case 0x174:
        case 0x180:
        case 0x1ac:
        case 0x1b4:
        case 0x1c0:
        case 0x1c4:
        case 0x1c8:
        case 0x1cc:
        case 0x1d4:
        case 0x1ec:
        case 0x1f0:
        case 0x1f4:
        case 0x1fc:
        case 0x200:
        case 0x218:
        case 0x22c:
        case 0x234:
        case 0x240:
        case 0x258:
        case 0x26c:
        case 0x274:
        case 0x280:
        case 0x298:
        case 0x2ac:
        case 0x2b4:
        case 0x2c0:
        case 0x2d8:
        case 0x2ec:
        case 0x2f4:
        case 0x300:
        case 0x318:
        case 0x32c:
        case 0x334:
        case 0x340:
        case 0x36c:
        case 0x374:
        case 0x380:
        case 0x3b4:
        case 0x3c0:
        case 0x3ec:
        case 0x3f0:
        case 0x3f4:
        case 0x3fc:
            break;
        default:
            return -1;
        }
    }
    *result_pointer = next_pointer;
    return 0;
}
