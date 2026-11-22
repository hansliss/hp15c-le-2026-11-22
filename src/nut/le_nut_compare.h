/* Native Nut register tests and unsigned comparisons from HP-15C LE. */
#ifndef LE_NUT_COMPARE_H
#define LE_NUT_COMPARE_H
#include "le_recovered.h"

/* Read-only tests B!=0, C!=0, A<C, A<B, A!=0 and A!=C, for all eight fields.
 * Uses cached P/WP/PQ masks as-is. W comparisons include all 64 slot bits.
 * On success return 0 and add the boolean result to the untagged next pointer.
 * Unsupported opcodes return -1 without changing output. State is never
 * changed; radix and previous carry are not inputs to these native handlers.
 */
int le_nut_compare_execute(const LeNutState *state, unsigned opcode,
                          uint32_t next_pointer, uint32_t *result_pointer);
#endif
