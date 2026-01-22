// GPU Driver Library Implementation

#include "gpu_driver.h"

void gpu_init(void) {
    // Initialize GPU (reset, configure, etc.)
    GPU->ctrl = 0x00000001;  // Enable GPU
}

void gpu_wait_idle(void) {
    // Wait for GPU to become idle
    while (GPU->status & GPU_STATUS_BUSY);
}

void gpu_clear(uint8_t color) {
    GPU->color = color;
    GPU->cmd = GPU_CMD_CLEAR;
    gpu_wait_idle();
}

void gpu_draw_pixel(uint16_t x, uint16_t y, uint8_t color) {
    GPU->x0 = x;
    GPU->y0 = y;
    GPU->color = color;
    GPU->cmd = GPU_CMD_PIXEL;
    // Pixel command is single-cycle, no need to wait
}

void gpu_draw_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color) {
    GPU->x0 = x0;
    GPU->y0 = y0;
    GPU->x1 = x1;
    GPU->y1 = y1;
    GPU->color = color;
    GPU->cmd = GPU_CMD_LINE;
    gpu_wait_idle();
}

void gpu_fill_rect(uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t color) {
    GPU->x0 = x;
    GPU->y0 = y;
    GPU->width = width;
    GPU->height = height;
    GPU->color = color;
    GPU->cmd = GPU_CMD_RECT;
    gpu_wait_idle();
}
