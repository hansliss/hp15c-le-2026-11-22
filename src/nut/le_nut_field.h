/* Non-arithmetic field handlers recovered from the HP-15C LE ARM firmware. */
#ifndef LE_NUT_FIELD_H
#define LE_NUT_FIELD_H
#include "le_recovered.h"

/* Clear/copy/exchange, field shifts and encoded C rotations. Uses cached field
 * masks as-is, including stale or diagnostic upper bits; never refreshes them.
 * Successful calls return 0 and preserve next_pointer. Unsupported opcodes
 * return -1 without modifying state or output. No pointer dereference, ROM
 * operand, display callback, radix or carry input is involved.
 */
int le_nut_field_execute(LeNutState *state, unsigned opcode,
                        uint32_t next_pointer, uint32_t *result_pointer);
#endif
