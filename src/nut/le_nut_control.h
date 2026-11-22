/* Status and arithmetic-mode operations recovered from LE ARM handlers. */
#ifndef LE_NUT_CONTROL_H
#define LE_NUT_CONTROL_H
#include "le_recovered.h"

/* next_pointer is the untagged post-fetch ROM pointer. Test-status returns
 * carry in its low bit; other supported operations leave it unchanged.
 * Unsupported opcodes return -1 without changing state or *result_pointer.
 * This models LE quirks, including 358 clearing status's upper byte and
 * 398 OR-ing the full status halfword into C after clearing only C[1:0].
 */
int le_nut_control_execute(LeNutState *state, unsigned opcode,
                           uint32_t next_pointer, uint32_t *result_pointer);
#endif
