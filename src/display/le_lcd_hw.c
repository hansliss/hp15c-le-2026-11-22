#include "le_lcd_hw.h"

#define SLCDC_CR UINT32_C(0xfffb4000)
#define SLCDC_MR UINT32_C(0xfffb4004)
#define SLCDC_FRR UINT32_C(0xfffb4008)
#define SLCDC_SR UINT32_C(0xfffb4010)
#define SLCDC_IER UINT32_C(0xfffb4020)
#define SLCDC_IMR UINT32_C(0xfffb4028)
#define SLCDC_ISR UINT32_C(0xfffb402c)
#define SUPC_MR UINT32_C(0xfffffd18)
#define SUPC_SR UINT32_C(0xfffffd24)
#define SUPC_KEY UINT32_C(0xa5000000)
#define SUPC_LCDS UINT32_C(0x100)

void le_lcd_hw_init(LeLcdHardware *hardware)
{
    if (hardware->read32(hardware->context, SLCDC_SR) == 1) {
        return;
    }
    hardware->write32(hardware->context, SLCDC_CR, 8);
    hardware->write32(hardware->context, SLCDC_MR, 0x201903);
    hardware->write32(hardware->context, SLCDC_FRR, 2);
    hardware->write32(hardware->context, SLCDC_CR, 1);
    while (hardware->read32(hardware->context, SLCDC_SR) != 1) {
        /* Wait for the same exact status value as the ARM code. */
    }
}

void le_lcd_hw_disable(LeLcdHardware *hardware)
{
    hardware->write32(hardware->context, SLCDC_CR, 2);
    uint32_t mode = hardware->read32(hardware->context, SUPC_MR);
    hardware->write32(hardware->context, SUPC_MR, (mode & ~UINT32_C(0x30)) | SUPC_KEY);
    while (hardware->read32(hardware->context, SUPC_SR) & SUPC_LCDS) {
        /* Wait for the supply status to clear. */
    }
}

void le_lcd_hw_set_contrast(LeLcdHardware *hardware, uint32_t contrast)
{
    uint32_t mode = hardware->read32(hardware->context, SUPC_MR);
    hardware->write32(hardware->context, SUPC_MR,
                      le_lcd_contrast_word(mode, contrast));
}

void le_lcd_hw_select_supply(LeLcdHardware *hardware, uint32_t mode)
{
    uint32_t previous = hardware->read32(hardware->context, SUPC_MR);
    hardware->write32(hardware->context, SUPC_MR,
                      (previous & ~UINT32_C(0x30)) | mode | SUPC_KEY);

    /* Preserve the comparison with the complete argument, not mode & 0x30. */
    const unsigned expect_on = mode != 0 && mode != 0x10;
    while (((hardware->read32(hardware->context, SUPC_SR) & SUPC_LCDS) != 0)
           != expect_on) {
        /* Wait for the selected supply. */
    }
}

void le_lcd_hw_enable(LeLcdHardware *hardware, uint32_t contrast)
{
    le_lcd_hw_select_supply(hardware, 0x30);
    /* Native fill call has r1 (length) = 0, r2 (byte) = 80: no writes.
     * Do not replace it with a RAM clear. Reset inside init may clear RAM.
     */
    le_lcd_hw_init(hardware);
    le_lcd_hw_set_contrast(hardware, contrast);
}

void le_lcd_hw_wait_frames(LeLcdHardware *hardware, uint32_t frames)
{
    hardware->write32(hardware->context, SLCDC_IER, 5);
    hardware->write32(hardware->context, SLCDC_IMR, 5);
    while (frames != 0) {
        while (!(hardware->read32(hardware->context, SLCDC_ISR) & 1)) {
            /* Read-to-clear EOF status; the backend advances frame events. */
        }
        --frames;
    }
    /* The original writes IER=0, not IDR=5. Preserve this observable behavior. */
    hardware->write32(hardware->context, SLCDC_IER, 0);
}

static uint32_t backend_read(void *context, uint32_t address)
{
    LeLcdHardware *hardware = context;
    return hardware->read32(hardware->context, address);
}

static void backend_write(void *context, uint32_t address, uint32_t value)
{
    LeLcdHardware *hardware = context;
    hardware->write32(hardware->context, address, value);
}

static void backend_enable(void *context, unsigned contrast)
{
    le_lcd_hw_enable(context, contrast);
}

static void backend_disable(void *context)
{
    le_lcd_hw_disable(context);
}

static void backend_wait(void *context, unsigned frames)
{
    le_lcd_hw_wait_frames(context, frames);
}

LeLcdIo le_lcd_hw_io(LeLcdHardware *hardware)
{
    const LeLcdIo io = {hardware, backend_read, backend_write,
                        backend_enable, backend_disable, backend_wait};
    return io;
}
