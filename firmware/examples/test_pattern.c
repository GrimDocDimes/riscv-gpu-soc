// Example: Draw a simple test pattern

#include "../drivers/gpu_driver.h"

void delay(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++);
}

int main(void) {
    // Initialize GPU
    gpu_init();
    
    // Clear screen to black
    gpu_clear(COLOR_BLACK);
    
    // Draw a white border
    gpu_draw_line(0, 0, 639, 0, COLOR_WHITE);       // Top
    gpu_draw_line(639, 0, 639, 479, COLOR_WHITE);   // Right
    gpu_draw_line(639, 479, 0, 479, COLOR_WHITE);   // Bottom
    gpu_draw_line(0, 479, 0, 0, COLOR_WHITE);       // Left
    
    // Draw colored rectangles
    gpu_fill_rect(50, 50, 100, 100, COLOR_RED);
    gpu_fill_rect(200, 50, 100, 100, COLOR_GREEN);
    gpu_fill_rect(350, 50, 100, 100, COLOR_BLUE);
    
    // Draw diagonal lines
    gpu_draw_line(50, 200, 590, 430, COLOR_YELLOW);
    gpu_draw_line(590, 200, 50, 430, COLOR_CYAN);
    
    // Infinite loop
    while (1) {
        delay(1000000);
    }
    
    return 0;
}
