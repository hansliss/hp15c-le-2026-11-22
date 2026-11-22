/* Native N/M/G transfers and constant loads from HP-15C LE ARM firmware. */
#ifndef LE_NUT_TRANSFER_H
#define LE_NUT_TRANSFER_H
#include "le_recovered.h"

/* immediate supplies the next halfword for opcode 130 only; successful 130
 * advances next_pointer by two. All other instructions leave it unchanged.
 * LC/G require selected_pointer to address P or Q, with that digit in 0..13.
 * LC additionally requires both P/Q in 0..13 and cached shift in 0..63.
 * Cached masks may be stale: their native effects are intentionally retained.
 * Returns 0, -1 (unsupported), or -2 (invalid pointer/cache). Errors leave
 * state and output untouched. All 64 register bits are retained where native
 * handlers retain them; G at digit 13 includes C bits 56..59.
 */
int le_nut_transfer_execute(LeNutState *state, unsigned opcode,
                           uint16_t immediate, uint32_t next_pointer,
                           uint32_t *result_pointer);
#endif
