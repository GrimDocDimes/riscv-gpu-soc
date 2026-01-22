# GPU Programming Guide

## Introduction

This guide explains how to program the GPU accelerator from RISC-V firmware to perform 2D graphics operations.

## Memory-Mapped Interface

The GPU accelerator is accessed through memory-mapped registers at base address `0x10000000`.

### C Header Definition

```c
#define GPU_BASE_ADDR 0x10000000

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
```

## GPU Commands

### 1. Clear Screen

Clears the entire frame buffer to black (or specified color).

```c
void gpu_clear(uint8_t color) {
    GPU->color = color;
    GPU->cmd = 0x04;  // CLEAR command
    while (GPU->status & 0x01);  // Wait for completion
}
```

### 2. Draw Pixel

Draws a single pixel at specified coordinates.

```c
void gpu_draw_pixel(uint16_t x, uint16_t y, uint8_t color) {
    GPU->x0 = x;
    GPU->y0 = y;
    GPU->color = color;
    GPU->cmd = 0x01;  // PIXEL command
}
```

### 3. Draw Line

Draws a line from (x0, y0) to (x1, y1) using Bresenham's algorithm.

```c
void gpu_draw_line(uint16_t x0, uint16_t y0, 
                   uint16_t x1, uint16_t y1, 
                   uint8_t color) {
    GPU->x0 = x0;
    GPU->y0 = y0;
    GPU->x1 = x1;
    GPU->y1 = y1;
    GPU->color = color;
    GPU->cmd = 0x02;  // LINE command
    while (GPU->status & 0x01);  // Wait for completion
}
```

### 4. Fill Rectangle

Fills a rectangle with specified color.

```c
void gpu_fill_rect(uint16_t x, uint16_t y, 
                   uint16_t width, uint16_t height, 
                   uint8_t color) {
    GPU->x0 = x;
    GPU->y0 = y;
    GPU->width = width;
    GPU->height = height;
    GPU->color = color;
    GPU->cmd = 0x03;  // RECT command
    while (GPU->status & 0x01);  // Wait for completion
}
```

## Status Register

Bit 0: BUSY - GPU is executing a command
- 0: Idle
- 1: Busy

Always check the BUSY bit before issuing a new command (except for PIXEL which is single-cycle).

## Color Format

The GPU uses 8-bit color with the following format:

- **Palette Mode**: 8-bit index into 256-color palette
- **Direct Mode**: RGB332 format
  - Bits [7:5]: Red (3 bits)
  - Bits [4:2]: Green (3 bits)
  - Bits [1:0]: Blue (2 bits)

### Common Colors (RGB332)

```c
#define COLOR_BLACK   0x00
#define COLOR_WHITE   0xFF
#define COLOR_RED     0xE0
#define COLOR_GREEN   0x1C
#define COLOR_BLUE    0x03
#define COLOR_YELLOW  0xFC
#define COLOR_CYAN    0x1F
#define COLOR_MAGENTA 0xE3
```

## Example Programs

### Example 1: Draw a Box

```c
void draw_box(void) {
    // Clear screen to black
    gpu_clear(COLOR_BLACK);
    
    // Draw white rectangle outline
    gpu_draw_line(100, 100, 540, 100, COLOR_WHITE);  // Top
    gpu_draw_line(540, 100, 540, 380, COLOR_WHITE);  // Right
    gpu_draw_line(540, 380, 100, 380, COLOR_WHITE);  // Bottom
    gpu_draw_line(100, 380, 100, 100, COLOR_WHITE);  // Left
}
```

### Example 2: Bouncing Ball

```c
void bouncing_ball(void) {
    int16_t x = 320, y = 240;
    int16_t dx = 2, dy = 3;
    uint8_t radius = 10;
    
    while (1) {
        // Clear previous position
        gpu_fill_rect(x - radius, y - radius, 
                     radius * 2, radius * 2, COLOR_BLACK);
        
        // Update position
        x += dx;
        y += dy;
        
        // Bounce off walls
        if (x <= radius || x >= 640 - radius) dx = -dx;
        if (y <= radius || y >= 480 - radius) dy = -dy;
        
        // Draw new position
        gpu_fill_rect(x - radius, y - radius, 
                     radius * 2, radius * 2, COLOR_RED);
        
        // Delay
        delay_ms(16);  // ~60 FPS
    }
}
```

### Example 3: Draw Grid

```c
void draw_grid(void) {
    gpu_clear(COLOR_BLACK);
    
    // Vertical lines
    for (int x = 0; x < 640; x += 40) {
        gpu_draw_line(x, 0, x, 479, COLOR_GREEN);
    }
    
    // Horizontal lines
    for (int y = 0; y < 480; y += 40) {
        gpu_draw_line(0, y, 639, y, COLOR_GREEN);
    }
}
```

## Performance Tips

1. **Batch Operations**: Group similar operations together to minimize status checks
2. **Avoid Polling**: Use interrupts if available (future enhancement)
3. **Use Hardware Acceleration**: Let the GPU handle line drawing instead of software loops
4. **Double Buffering**: Not currently supported, but plan for future enhancement

## Limitations

- No hardware clipping (coordinates must be within bounds)
- No alpha blending or transparency
- No hardware sprites or texture mapping
- Single frame buffer (no double buffering)

## Future Enhancements

- Circle/ellipse drawing
- Polygon fill
- Sprite support
- Hardware scrolling
- Interrupt support for command completion
