OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)
MEMORY
{
    flash (rx)  : ORIGIN = 0x00420000, LENGTH = 512K    /* 定义 Flash 区域 */
    ram   (rwx) : ORIGIN = 0x00030000, LENGTH = 96K     /* 定义 RAM 区域 */
}

STACK_SIZE = 0x1000;
ENTRY(reset)

SECTIONS
{
    /* 将 .text 段放入 Flash 中 */
    .text :
    {
        . = ALIGN(4);
        PROVIDE(__spl_start = .);
        *(.text .text.*)
        . = ALIGN(4);
        
    } > flash

    /* 将 .rodata 段也放入 Flash 中 */
    .rodata :
    { 
        . = ALIGN(4);
        *(.rodata)
        . = ALIGN(4);
    } > flash

    /* .data 段在 Flash 中存储初始化数据，在 RAM 中运行 */
    .data : 
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data .data.*)
        . = ALIGN(4);
        _edata = .;
    } > ram AT > flash

    /* .bss 段仅在 RAM 中，不需要初始化 */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _sbss = . ;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
    } > ram

    /* 栈段放入 RAM 中 */
    .stack (NOLOAD):
    {
        . = ALIGN(8);
        __stack_srv_start = .;
        . += STACK_SIZE;
        __stack_srv_end = .;
    } > ram

    /* 异常处理表，放入 Flash 中 */
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

