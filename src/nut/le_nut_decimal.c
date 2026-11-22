#include "le_nut_decimal.h"

/* XOR identifies nibble carries in the binary sum. The native correction
 * clears the top correction bit when the full addition carries beyond bit 63.
 * Correction bits lie at nibble bit 3, so the two shifts do not lose any
 * nonzero cross-word bits in the original pair of 32-bit instructions. */
static uint64_t corrected_sum(uint64_t first, uint64_t second)
{
    uint64_t sum = first + second;
    uint64_t nibble_carries = first ^ second ^ sum;
    uint64_t correction = UINT64_C(0x8888888888888888) & ~(nibble_carries >> 1);
    if (sum < first)
        correction &= ~UINT64_C(0x8000000000000000);
    return sum - (correction >> 2) - (correction >> 1);
}

uint64_t le_nut_decimal_add(uint64_t left, uint64_t right)
{
    /* Overflow of this initial bias is discarded by the native ADC pair. */
    return corrected_sum(left + UINT64_C(0x6666666666666666), right);
}

uint64_t le_nut_decimal_subtract(uint64_t left, uint64_t right)
{
    /* The native primitive takes right first, then left; its increment of
     * left wraps before the complemented-right addition. */
    return corrected_sum(~right, left + UINT64_C(1));
}

unsigned le_nut_masked_add(uint64_t left, uint64_t right,
                           uint64_t *destination, uint64_t mask, uint8_t mode)
{
    left &= mask;
    right &= mask;
    uint64_t result = mode ? left + right : le_nut_decimal_add(left, right);
    *destination = (*destination & ~mask) | (result & mask);
    return (result & ~mask) != 0;
}

unsigned le_nut_masked_subtract(uint64_t left, uint64_t right,
                                uint64_t *destination, uint64_t mask, uint8_t mode)
{
    left &= mask;
    right &= mask;
    unsigned borrow = left < right;
    uint64_t result = mode ? left - right : le_nut_decimal_subtract(left, right);
    *destination = (*destination & ~mask) | (result & mask);
    return borrow;
}
