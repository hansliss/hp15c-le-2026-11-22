#include "board_services.h"
#include "le_lcd_hw.h"
#include "le_nut_pointer.h"

#define KEY_QUEUE_BASE UINT32_C(0x200878)
#define QUEUE_READ 10u
#define QUEUE_WRITE 11u
#define QUEUE_DATA 12u
#define QUEUE_SIZE 16u
#define QUEUE_BYTE(offset) (*(volatile uint8_t *)(uintptr_t)(KEY_QUEUE_BASE + (offset)))

unsigned board_key_queue_empty(void)
{
    unsigned read = QUEUE_BYTE(QUEUE_READ);
    return read == QUEUE_BYTE(QUEUE_WRITE);
}

uintptr_t board_key_queue_clear(void)
{
    QUEUE_BYTE(QUEUE_WRITE) = 0;
    QUEUE_BYTE(QUEUE_READ) = 0;
    return KEY_QUEUE_BASE;
}

int board_key_queue_peek(void)
{
    if (board_key_queue_empty())
        return -1;
    return QUEUE_BYTE(QUEUE_DATA + QUEUE_BYTE(QUEUE_READ));
}

int board_key_queue_get(void)
{
    unsigned read = QUEUE_BYTE(QUEUE_READ);
    if (read == QUEUE_BYTE(QUEUE_WRITE))
        return -1;
    int key = QUEUE_BYTE(QUEUE_DATA + read);
    unsigned next = (read + 1u) & 0xffu;
    QUEUE_BYTE(QUEUE_READ) = next == QUEUE_SIZE ? 0 : (uint8_t)next;
    return key;
}

void board_key_queue_add(unsigned key)
{
    unsigned read = QUEUE_BYTE(QUEUE_READ);
    unsigned write = QUEUE_BYTE(QUEUE_WRITE);
    /* Retain the original full checks, including its asymmetric wrap case. */
    if (write == read - 1u || (write == QUEUE_SIZE && read == 0))
        return;
    QUEUE_BYTE(QUEUE_DATA + write) = (uint8_t)key;
    unsigned next = write + 1u;
    QUEUE_BYTE(QUEUE_WRITE) = next == QUEUE_SIZE ? 0 : (uint8_t)next;
}

unsigned board_image_checksum(void)
{
    const volatile uint32_t *flash = (const volatile uint32_t *)(uintptr_t)0x100000;
    uint32_t sum = 0;
    for (unsigned offset = 0; offset < 0x20000 / sizeof(*flash); ++offset) {
        uint32_t word = flash[offset];
        sum += word + (word >> 8) + (word >> 16) + (word >> 24);
    }
    return (sum - *(const volatile uint8_t *)(uintptr_t)0x111c98) & 0xffu;
}

uint32_t board_init_field_masks(uint32_t entry, LeNutState *state)
{
    unsigned selected = *(const uint8_t *)(uintptr_t)state->selected_pointer;
    le_nut_refresh_fields(state, selected);
    return entry;
}

uint32_t board_set_contrast(uint32_t contrast)
{
    volatile uint32_t *mode = (volatile uint32_t *)(uintptr_t)0xfffffd18;
    uint32_t value = le_lcd_contrast_word(*mode, contrast);
    *mode = value;
    return value;
}
