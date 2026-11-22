#ifndef BOARD_SERVICES_H
#define BOARD_SERVICES_H

#include "le_recovered.h"

/* The scanner and the native foreground share the same 16-byte key ring. */
unsigned board_key_queue_empty(void);
uintptr_t board_key_queue_clear(void);
int board_key_queue_peek(void);
int board_key_queue_get(void);
void board_key_queue_add(unsigned key);

/* Return the flash byte sum with the stored checksum byte excluded. */
unsigned board_image_checksum(void);

/* Rebuild the Nut field cache at interpreter entry. */
uint32_t board_init_field_masks(uint32_t entry, LeNutState *state);

/* Set the four-bit LCD contrast and return the written supply-mode word. */
uint32_t board_set_contrast(uint32_t contrast);

#endif
