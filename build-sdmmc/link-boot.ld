OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)
MEMORY
{
    flash (rx) : ORIGIN = 0x00420000, LENGTH = 512K
    ram (rwx) : ORIGIN = 0x00030000, LENGTH = 96K
}
STACK_SIZE = 0x1000;
ENTRY(reset)
SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        PROVIDE(__spl_start = .);
        *(.text .text.*)
        . = ALIGN(4);
    } > flash
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        . = ALIGN(4);
    } > flash
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        . = ALIGN(4);
        _edata = .;
    } > ram AT > flash
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _sbss = . ;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
    } > ram
    .stack (NOLOAD):
    {
        . = ALIGN(8);
        __stack_srv_start = .;
        . += STACK_SIZE;
        __stack_srv_end = .;
    } > ram
    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > flash
    . = ALIGN(4);
    PROVIDE(__spl_end = .);
    PROVIDE(__spl_size = __spl_end - __spl_start);
    PROVIDE(data_load_addr = LOADADDR(.data));
    _end = . ;
}
