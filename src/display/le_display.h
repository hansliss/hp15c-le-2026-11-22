/* Pure reconstruction of the HP-15C LE packed-display routing block. */
#ifndef LE_DISPLAY_H
#define LE_DISPLAY_H

#include <stdint.h>

/* LCD user RAM words at 0xfffb4200..0xfffb421f, including odd words.
 * Values at state offsets 0xb0 and 0xb8 are supplied explicitly: no host
 * dependency on the still-provisional architectural RAM-number mapping.
 * Each contributes bits 6..55. Only the 100 routed bits are changed;
 * all other LCD bits retain their input values.
 *
 * This always applies the mapping. The ARM cache, display-off and blink
 * policy, battery annunciator, frame latch and controller I/O are outside
 * this function. See DISPLAY_RECOVERY.md for contracts and evidence.
 */
void le_display_map(uint64_t state_b0, uint64_t state_b8,
                    uint32_t lcd_words[8]);

/* Ordered word I/O for the same mapper. Indices are 0,2,4,6 within LCD
 * user RAM. Each source bit performs one read/modify/write, in table order.
 * The callbacks must be valid and synchronous.
 */
typedef struct {
    void *context;
    uint32_t (*read_word)(void *context, unsigned index);
    void (*write_word)(void *context, unsigned index, uint32_t value);
} LeDisplayWordIo;

void le_display_map_io(uint64_t state_b0, uint64_t state_b8,
                       const LeDisplayWordIo *io);

#endif
