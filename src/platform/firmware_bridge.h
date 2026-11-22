#ifndef FIRMWARE_BRIDGE_H
#define FIRMWARE_BRIDGE_H

#include "le_recovered.h"

/* Convert the native ROM-relative, carry-tagged entry offset to a flash
 * pointer. Run Nut instructions until STOP returns the next pointer. */
uint32_t le_mixed_dispatch(LeNutState *state, uint32_t offset);

/* Opcode adapters take an untagged post-fetch pointer and return the next
 * pointer with carry in bit zero where the operation sets it. */
uint32_t le_mixed_arithmetic_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_compare_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_control_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_field_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_misc_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_pointer_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_transfer_execute(LeNutState *state, unsigned opcode, uint32_t next);
uint32_t le_mixed_flow_execute(LeNutState *state, unsigned opcode, uint32_t next,
                               uint32_t previous_carry);

/* The high word reports STOP and the low word contains the next pointer. */
uint64_t le_mixed_platform_execute(LeNutState *state, unsigned opcode, uint32_t next);

/* RAM operations neither branch nor set carry. */
void le_mixed_ram_execute(LeNutState *state, unsigned opcode);

/* Render directly, or route an opcode's refresh through display policy. */
void le_mixed_lcd_update(LeNutState *state);
void le_mixed_display_request(LeNutState *state);

#endif
