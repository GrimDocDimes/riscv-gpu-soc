// GPU Driver Library Header
// Provides C API for controlling the GPU accelerator

#ifndef GPU_DRIVER_H
#define GPU_DRIVER_H

#include <stdint.h>

// GPU base address
#define GPU_BASE_ADDR 0x10000000

// GPU register structure
typedef struct {
    volatile uint32_t ctrl;      // 0x00: Control register
    volatile uint32_t status;    // 0x04: Status register
    volatile uint32_t cmd;       // 0x08: Command register
    volatile uint32_t x0;        // 0x0C: X coordinate 0
    volatile uint32_t y0;        // 0x10: Y coordinate 0
    volatile uint32_t x1;        // 0x14: X coordinate 1
    volatile uint32_t y1;        // 0x18: Y coordinate 1
    volatile uint32_t color;     // 0x1C: Draw color
    volatile uint32_t width;     // 0x20: Rectangle width
    volatile uint32_t height;    // 0x24: Rectangle height
} GPU_Regs;

#define GPU ((GPU_Regs*)GPU_BASE_ADDR)

// GPU commands
#define GPU_CMD_NOP   0x00
#define GPU_CMD_PIXEL 0x01
#define GPU_CMD_LINE  0x02
#define GPU_CMD_RECT  0x03
#define GPU_CMD_CLEAR 0x04

// Status bits
#define GPU_STATUS_BUSY 0x01

// Color definitions (RGB332 format)
#define COLOR_BLACK   0x00
#define COLOR_WHITE   0xFF
#define COLOR_RED     0xE0
#define COLOR_GREEN   0x1C
#define COLOR_BLUE    0x03
#define COLOR_YELLOW  0xFC
#define COLOR_CYAN    0x1F
#define COLOR_MAGENTA 0xE3

// Function prototypes
void gpu_init(void);
void gpu_wait_idle(void);
void gpu_clear(uint8_t color);
void gpu_draw_pixel(uint16_t x, uint16_t y, uint8_t color);
void gpu_draw_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color);
void gpu_fill_rect(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t color);

#endif // GPU_DRIVER_H
