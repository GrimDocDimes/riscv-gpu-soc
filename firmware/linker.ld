/* Linker script for RISC-V + GPU Accelerator SoC */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    /* Instruction memory: 32KB at 0x00000000 */
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 32K
    
    /* Data memory: 32KB at 0x00008000 */
    DMEM (rw)  : ORIGIN = 0x00008000, LENGTH = 32K
}

SECTIONS
{
    /* Code section in instruction memory */
    .text : {
        *(.text.start)      /* Startup code first */
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > IMEM
    
    /* Data section in data memory */
    .data : {
        _data_start = .;
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
        _data_end = .;
    } > DMEM AT > IMEM
    
    _data_load = LOADADDR(.data);
    
    /* BSS section (uninitialized data) */
    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > DMEM
    
    /* Stack grows downward from top of data memory */
    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
    
    /* Heap (if needed) */
    .heap : {
        _heap_start = .;
        . = . + 1K;  /* 1KB heap */
        _heap_end = .;
    } > DMEM
}
