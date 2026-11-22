/* Remaining pure register and ROM-read operations in the LE Nut interpreter. */
#ifndef LE_NUT_MISC_H
#define LE_NUT_MISC_H
#include "le_recovered.h"

/* Only ROM-to-C (330) invokes this callback, with the 16-bit address from C
 * digits 3..6. Return the entire native halfword, without a ten-bit mask. */
typedef uint16_t (*LeNutMiscReadRom)(void *context, uint16_t address);

typedef enum {
    LE_NUT_MISC_EARLIER = 0, /* 2009 and April 11: 3AC is a no-op */
    LE_NUT_MISC_APRIL15 = 1
} LeNutMiscVariant;

/* Preserve cached masks, pointers and radix. Returns 0 on success, -1 for
 * unsupported opcodes, -2 for ROM-to-C without a reader. Errors preserve state
 * and output. The callback may inspect/change state: native 330 retains the
 * pre-read upper low-word C bits, but preserves the post-read high word.
 * Keyboard-related no-op 3C8 is deliberately outside this interface. */
int le_nut_misc_execute(LeNutMiscVariant variant, LeNutState *state,
                       unsigned opcode, uint32_t next_pointer,
                       LeNutMiscReadRom read_rom, void *context,
                       uint32_t *result_pointer);
#endif
