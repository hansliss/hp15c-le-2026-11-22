/* Latest-image ARM/IAR state bridge for the experimental mixed display build.
 * No initialized data, heap or new fixed SRAM allocation is permitted.
 */
#include "firmware_bridge.h"
#include "le_lcd_hw.h"
#include "le_recovered.h"

#ifndef LE_MIXED_QUOTA
#error "Select the mixed build quota mode explicitly"
#endif

#define CACHE ((volatile uint64_t *)(uintptr_t)0x00200000)
#define COUNTER (*(volatile uint32_t *)(uintptr_t)0x00200010)
#define MODE (*(volatile uint8_t *)(uintptr_t)0x002008a8)

typedef struct {
    volatile LeNutState *native;
    LeLcdState display;
    LeDisplayPolicy policy;
} DisplayBridge;

static void publish(DisplayBridge *bridge)
{
    bridge->native->display_off = bridge->display.flags.off;
    bridge->native->display_blink = bridge->display.flags.blink;
    CACHE[0] = bridge->display.cache[0];
    CACHE[1] = bridge->display.cache[1];
    COUNTER = bridge->policy.counter;
}

static void refresh(DisplayBridge *bridge)
{
    bridge->display.flags.off = bridge->native->display_off;
    bridge->display.flags.blink = bridge->native->display_blink;
    bridge->display.source_b0 = bridge->native->ram_candidate[9];
    bridge->display.source_b8 = bridge->native->ram_candidate[10];
    bridge->display.battery = bridge->native->trailing_state[1];
    bridge->display.mode = MODE;
    bridge->display.cache[0] = CACHE[0];
    bridge->display.cache[1] = CACHE[1];
    bridge->policy.counter = COUNTER;
}

static uint32_t read_register(void *context, uint32_t address)
{
    DisplayBridge *bridge = context;
    publish(bridge);
    uint32_t value = *(volatile uint32_t *)(uintptr_t)address;
    refresh(bridge);
    return value;
}

static void write_register(void *context, uint32_t address, uint32_t value)
{
    DisplayBridge *bridge = context;
    publish(bridge);
    *(volatile uint32_t *)(uintptr_t)address = value;
    refresh(bridge);
}

static void render(void *context, LeDisplayPolicy *policy, LeDisplayFlags *flags)
{
    DisplayBridge *bridge = context;
    LeLcdHardware hardware = {bridge, read_register, write_register};
    LeLcdIo io = le_lcd_hw_io(&hardware);
    (void)policy;
    (void)flags; /* Same object as bridge->display.flags. */
    le_lcd_update(LE_LCD_APRIL, &bridge->display, &io);
}

void le_mixed_lcd_update(LeNutState *state)
{
    DisplayBridge bridge;
    bridge.native = state;
    bridge.policy.mode = LE_MIXED_QUOTA;
    refresh(&bridge);
    render(&bridge, &bridge.policy, &bridge.display.flags);
    publish(&bridge);
}

void le_mixed_display_request(LeNutState *state)
{
    DisplayBridge bridge;
    bridge.native = state;
    bridge.policy.mode = LE_MIXED_QUOTA;
    refresh(&bridge);
    le_display_request(&bridge.policy, &bridge.display.flags, render, &bridge);
    publish(&bridge);
}
