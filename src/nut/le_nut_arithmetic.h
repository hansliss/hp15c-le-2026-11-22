/* Class-2 arithmetic entries, recovered from the LE firmware. */
#ifndef LE_NUT_ARITHMETIC_H
#define LE_NUT_ARITHMETIC_H
#include "le_recovered.h"

/* Operations 9..21 in all eight fields. Uses raw cached masks and shift bytes;
 * a cached shift >=64 produces zero for the constructed one, as on ARM.
 * Writes only the selected A/C destination and returns the tagged next ROM
 * pointer. Unsupported returns -1 with state and output unchanged.
 * The separate April-15 3AC extension remains outside this interface. */
int le_nut_arithmetic_execute(LeNutState *state, unsigned opcode,
                             uint32_t next_pointer, uint32_t *result_pointer);
#endif
