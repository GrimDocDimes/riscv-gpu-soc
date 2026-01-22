/* RISC-V Startup Code */
/* Minimal boot code for PicoRV32 */

    .section .text.start
    .global _start

_start:
    /* Set up stack pointer */
    lui sp, %hi(_stack_top)
    addi sp, sp, %lo(_stack_top)
    
    /* Clear BSS section */
    lui a0, %hi(_bss_start)
    addi a0, a0, %lo(_bss_start)
    lui a1, %hi(_bss_end)
    addi a1, a1, %lo(_bss_end)
    
clear_bss:
    beq a0, a1, bss_done
    sw zero, 0(a0)
    addi a0, a0, 4
    j clear_bss
    
bss_done:
    /* Copy data section from ROM to RAM (if needed) */
    /* For now, skip this as we're using BRAM */
    
    /* Call main function */
    call main
    
    /* If main returns, loop forever */
_halt:
    j _halt

    .global _exit
_exit:
    j _halt
