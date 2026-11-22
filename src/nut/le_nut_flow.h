/* Native LE Nut branches, return ring and C/address transfers. */
#ifndef LE_NUT_FLOW_H
#define LE_NUT_FLOW_H
#include "le_recovered.h"

#define LE_NUT_WATCHDOG_ADDRESS UINT32_C(0xfffffd50)
#define LE_NUT_WATCHDOG_RESTART UINT32_C(0xa5000001)

/* Called at the native restart-write point, after a taken long call pushes its
 * return address. The target bridge performs the volatile watchdog write.
 * Analysis callbacks may inspect/change state; subsequent native effects must
 * retain those changes. No callback is made for an untaken branch or a forward short branch. */
typedef void (*LeNutFlowWatchdog)(void *context, LeNutState *state);

/* operand is the next halfword for class 1 only. next_pointer is post-fetch;
 * the model consumes that operand even for an untaken long branch. The bridge
 * supplies it from ROM. Normal previous_carry is 0/1; raw diagnostic values
 * retain native full-word comparison for long branches and bit-0 tests for
 * short branches/conditional returns. POP C/GOTO C retain native quirks.
 * Returns 0; -1 unsupported; -2 invalid push index (>3); -3 watchdog-servicing branch with
 * no watchdog callback. Errors leave state/output unchanged. Pop normalizes
 * any byte index before access. Returned VM pointers are not dereferenced.
 */
int le_nut_flow_execute(LeNutState *state, unsigned opcode,
                       uint32_t next_pointer, uint32_t previous_carry,
                       uint16_t operand, LeNutFlowWatchdog watchdog, void *context,
                       uint32_t *result_pointer);
#endif
