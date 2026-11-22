/* Low-level LCD helpers recovered from the supplied HP-15C LE firmwares. */
#ifndef LE_LCD_HW_H
#define LE_LCD_HW_H

#include "le_lcd.h"

typedef struct {
    void *context;
    uint32_t (*read32)(void *context, uint32_t address);
    void (*write32)(void *context, uint32_t address, uint32_t value);
} LeLcdHardware;

/* These synchronous routines retain the firmware's unbounded polling.
 * The backend must supply real status changes or explicit simulated events.
 * No guessed timeouts, interrupt handlers or per-instruction timing are added.
 */
void le_lcd_hw_init(LeLcdHardware *hardware);
void le_lcd_hw_select_supply(LeLcdHardware *hardware, uint32_t mode);
/* Replace the contrast nibble and supply the controller's write key. */
static inline uint32_t le_lcd_contrast_word(uint32_t mode, uint32_t contrast)
{
    return (mode & ~UINT32_C(0xf)) | (contrast & 0xfu) | UINT32_C(0xa5000000);
}

void le_lcd_hw_set_contrast(LeLcdHardware *hardware, uint32_t contrast);
void le_lcd_hw_enable(LeLcdHardware *hardware, uint32_t contrast);
void le_lcd_hw_disable(LeLcdHardware *hardware);
void le_lcd_hw_wait_frames(LeLcdHardware *hardware, uint32_t frames);

/* Bind the recovered helpers to the renderer's backend. The hardware object
 * and its context must outlive the returned interface and all calls using it.
 */
LeLcdIo le_lcd_hw_io(LeLcdHardware *hardware);

#endif
