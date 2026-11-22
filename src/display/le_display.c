#include "le_display.h"

#include <stddef.h>

typedef struct {
    unsigned word;
    uint32_t mask;
} SegmentRoute;

#include "le_display_routes.inc"

static uint32_t array_read(void *context, unsigned index)
{
    const uint32_t *words = context;
    return words[index];
}

static void array_write(void *context, unsigned index, uint32_t value)
{
    uint32_t *words = context;
    words[index] = value;
}

void le_display_map(uint64_t state_b0, uint64_t state_b8,
                    uint32_t lcd_words[8])
{
    const LeDisplayWordIo io = {lcd_words, array_read, array_write};
    le_display_map_io(state_b0, state_b8, &io);
}

void le_display_map_io(uint64_t state_b0, uint64_t state_b8,
                       const LeDisplayWordIo *io)
{
    const uint64_t sources[2] = {state_b0 >> 6, state_b8 >> 6};

    for (size_t source = 0; source < 2; ++source) {
        for (size_t bit = 0; bit < 50; ++bit) {
            const SegmentRoute *route = &segment_routes[source * 50 + bit];
            uint32_t word = io->read_word(io->context, route->word);

            if (sources[source] & (UINT64_C(1) << bit)) {
                word |= route->mask;
            } else {
                word &= ~route->mask;
            }
            io->write_word(io->context, route->word, word);
        }
    }
}
