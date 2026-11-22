/* Exact packed arithmetic recovered from the LE ARM helpers. */
#ifndef LE_NUT_DECIMAL_H
#define LE_NUT_DECIMAL_H
#include <stdint.h>

/* Operate on all 16 packed nibbles, including non-BCD values. These reproduce
 * native binary correction and wrapping, rather than normalizing inputs. */
uint64_t le_nut_decimal_add(uint64_t left, uint64_t right);
uint64_t le_nut_decimal_subtract(uint64_t left, uint64_t right);

/* The parameter order also matches the native masked-helper ABI: operands in
 * r0:r1/r2:r3, destination at incoming SP+0, mask at +8, mode byte at +16.
 * Preserve destination bits outside mask. Return native carry/borrow 0 or 1.
 * Mode zero selects decimal; every nonzero mode selects binary/hex. */
unsigned le_nut_masked_add(uint64_t left, uint64_t right,
                           uint64_t *destination, uint64_t mask, uint8_t mode);
unsigned le_nut_masked_subtract(uint64_t left, uint64_t right,
                                uint64_t *destination, uint64_t mask, uint8_t mode);
#endif
