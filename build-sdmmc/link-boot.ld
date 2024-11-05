OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)
MEMORY
{
  ram (rwx) : ORIGIN = 0x00020000, LENGTH = 96K
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
    } > ram
    . = ALIGN(4);
    .ARM.exidx : {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > ram
    PROVIDE(__spl_end = .);
    PROVIDE(__spl_size = __spl_end - __spl_start);
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
    . = ALIGN(4);
    _end = . ;
}
