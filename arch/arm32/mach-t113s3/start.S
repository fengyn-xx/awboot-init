#include <arch/arm32/include/linkage.h>

#define CONFIG_NBOOT_STACK	0x38000

#define  ARMV7_USR_MODE        0x10
#define  ARMV7_FIQ_MODE        0x11
#define  ARMV7_IRQ_MODE        0x12
#define  ARMV7_SVC_MODE        0x13
#define  ARMV7_MON_MODE        0x16
#define  ARMV7_ABT_MODE        0x17
#define  ARMV7_UND_MODE        0x1b
#define  ARMV7_SYSTEM_MODE     0x1f
#define  ARMV7_MODE_MASK       0x1f
#define  ARMV7_FIQ_MASK        0x40
#define  ARMV7_IRQ_MASK        0x80

.arm
.globl reset
.text

reset:
	/* Boot head information for BROM */
	.long 0xea000016
	.byte 'e', 'G', 'O', 'N', '.', 'B', 'T', '0'
	.long 0x12345678                                /* checksum */
	.long __spl_size                                /* spl size */
	.long 0x30                                              /* boot header size */
	.long 0x30303033                                /* boot header version */
	.long 0x00038000                                /* return value */
	.long 0x00038000                                /* run address */
	.long 0x0                                               /* eGON version */
	.byte 0x00, 0x00, 0x00, 0x00    /* platform information - 8byte */
	.byte 0x34, 0x2e, 0x30, 0x00

/*
 * The actual reset code
 */
	mrs r0, cpsr
	bic r0, r0, #ARMV7_MODE_MASK
	orr r0, r0, #ARMV7_SVC_MODE
	orr r0, r0, #(ARMV7_IRQ_MASK | ARMV7_FIQ_MASK)
	bic r0, r0, #(1<<9)     @set little-endian
	msr cpsr_c, r0

/* Set vector base address register */

	ldr r0, =_vector
	mcr p15, 0, r0, c12, c0, 0
	mrc p15, 0, r0, c1, c0, 0
	bic r0, #(1 << 13)
	mcr p15, 0, r0, c1, c0, 0

	mrc     p15, 0, r0, c1, c0, 0
	bic     r0, r0, #0x00002000     @ clear bits 13 (--V-)
	bic     r0, r0, #0x00000007     @ clear bits 2:0 (-CAM)
	orr     r0, r0, #0x00000800     @ set bit 11 (Z---) BTB
	bic     r0, r0, #0x00001000     @ clear bit 12 (I) I-cache
	mcr     p15, 0, r0, c1, c0, 0

	/* Enable neon/vfp unit */
	mrc p15, 0, r0, c1, c0, 2
	orr r0, r0, #(0xf << 20)
	mcr p15, 0, r0, c1, c0, 2
	isb
	mov r0, #0x40000000
	vmsr fpexc, r0

	/* Set stack pointer */
	ldr sp, =__stack_srv_end

	bl  clear_bss

	/*
		* disable interrupts (FIQ and IRQ), also set the cpu to SVC32 mode,
		* except if in HYP mode already
		*/
	mrs     r0, cpsr
	and     r1, r0, #0x1f           @ mask mode bits
	teq     r1, #0x1a               @ test for HYP mode
	bicne   r0, r0, #0x1f           @ clear all mode bits
	orrne   r0, r0, #0x13           @ set SVC mode
	orr     r0, r0, #0xc0           @ disable FIQ and IRQ
	msr     cpsr,r0

	@set cntfrq to 24M
	ldr r0, =24000000
	mcr p15, 0, r0, c14, c0, 0
	bl prepare_main

	bl main

	clear_bss:
	ldr     r0, =_sbss
	ldr     r1, =_ebss
	mov     r2, #0

	clbss_1:
	stmia   r0!, {r2}
	cmp r0, r1
	blt clbss_1

	mov pc, lr

_vector:
	b reset
	ldr pc, _undefined_instruction
	ldr pc, _software_interrupt
	ldr pc, _prefetch_abort
	ldr pc, _data_abort
	ldr pc, _not_used
	ldr pc, _irq
	ldr pc, _fiq

_undefined_instruction:
	.word undefined_instruction
_software_interrupt:
	.word software_interrupt
_prefetch_abort:
	.word prefetch_abort
_data_abort:
	.word data_abort
_not_used:
	.word not_used
_irq:
	.word irq
_fiq:
	.word fiq

.macro save_regs
	str lr, [sp, #-4]
	mrs lr, spsr_all
	str lr, [sp, #-8]
	str r1, [sp, #-12]
	str r0, [sp, #-16]
	mov r0, sp
	cps #0x13
	ldr r1, [r0, #-4]
	str r1, [sp, #-4]!
	ldr r1, [r0, #-8]
	str r1, [sp, #-(4 * 16)]
	ldr r1, [r0, #-12]
	ldr r0, [r0, #-16]
	stmdb sp, {r0 - r14}^
	sub sp, sp, #(4 * 16)
	ldr r4, [sp]
	and r0, r4, #0x1f
	cmp r0, #0x10
	beq 10f
	cmp r0, #0x13
	beq 11f
	b .
11:	add r1, sp, #(4 * 17)
	str r1, [sp, #(4 * 14)]
	str lr, [sp, #(4 * 15)]
10:	add r1, sp, #(4 * 17)
	str r1, [sp, #-4]!
	mov r0, sp
.endm

.macro restore_regs
	mov r12, sp
	ldr sp, [r12], #4
	ldr r1, [r12], #4
	msr spsr_cxsf, r1
	and r0, r1, #0x1f
	cmp r0, #0x10
	beq 20f
	cmp r0, #0x13
	beq 21f
	b .
20:	ldr lr, [r12, #(4 * 15)]
	ldmia r12, {r0 - r14}^
	movs pc, lr
21:	ldm r12, {r0 - r15}^
	mov r0, r0
.endm

/*
 * Exception handlers
 */
	.align 5
undefined_instruction:
	sub lr, lr, #4
	save_regs
	bl arm32_do_undefined_instruction
	restore_regs

	.align 5
software_interrupt:
	sub lr, lr, #4
	save_regs
	bl arm32_do_software_interrupt
	restore_regs

	.align 5
prefetch_abort:
	sub lr, lr, #4
	save_regs
	bl arm32_do_prefetch_abort
	restore_regs

	.align 5
data_abort:
	sub lr, lr, #8
	save_regs
	bl arm32_do_data_abort
	restore_regs

	.align 5
not_used:
	b .

	.align 5
irq:
	sub lr, lr, #4
	save_regs
	bl arm32_do_irq
	restore_regs

	.align 5
fiq:
	sub lr, lr, #4
	save_regs
	bl arm32_do_fiq
	restore_regs
	
prepare_main:
	ldr	r0,=0x01FFFFFF
	ldr	r1,=0x02000098 
	str	r0,[r1]
	ldr	r0,=0x00000000 
	ldr	r1,=0x20000A0
	str	r0,[r1]
	ldr r0, =0x02000030   // 基础地址
    mov r1, #4            // pin_num = 4
    and r1, r1, #0x1f     // pin_num &= ((1 << 5) - 1)
    mov r2, #7            // cfg = 7
    lsr r3, r1, #3        // (pin_num >> 3)
    lsl r3, r3, #2        // << 2
    add r3, r0, r3        // addr = 0x02000030 + (pin_num >> 3) << 2
    ldr r4, [r3]          // val = read32(addr)
    and r5, r1, #0x7      // (pin_num & 0x7)
    lsl r5, r5, #2        // << 2
    bic r4, r4, #(0xf << 0x10)  // val &= ~(0xf << ((pin_num & 0x7) << 2))
    and r6, r2, #0xf      // (cfg & 0xf)
    lsl r6, r6, r5        // << ((pin_num & 0x7) << 2)
    orr r4, r4, r6        // val |= ((cfg & 0xf) << ((pin_num & 0x7) << 2))
    str r4, [r3]          // write32(addr, val)

    mov r1, #5            // pin_num = 5
    and r1, r1, #0x1f     // pin_num &= ((1 << 5) - 1)
    lsr r3, r1, #3        // (pin_num >> 3)
    lsl r3, r3, #2        // << 2
    add r3, r0, r3        // addr = 0x02000030 + (pin_num >> 3) << 2
    ldr r4, [r3]          // val = read32(addr)
    and r5, r1, #0x7      // (pin_num & 0x7)
    lsl r5, r5, #2        // << 2
    bic r4, r4, #(0xf << 0x14)  // val &= ~(0xf << ((pin_num & 0x7) << 2))
    and r6, r2, #0xf      // (cfg & 0xf)
    lsl r6, r6, r5        // << ((pin_num & 0x7) << 2)
    orr r4, r4, r6        // val |= ((cfg & 0xf) << ((pin_num & 0x7) << 2))
    str r4, [r3]          // write32(addr, val)

    ldr r0, =0x02001000   // 基础地址
    ldr r1, =0x0200190c    // addr = 0x02001000 + 0x90c
    ldr r2, [r1]          // val = read32(addr)
    orr r2, r2, #(0x20) // val |= (1 << 5)
    str r2, [r1]          // write32(addr, val)

    ldr r2, [r1]          // 重新读取 addr
    orr r2, r2, #(0x200000)// val |= (1 << 21)
    str r2, [r1]          // write32(addr, val)
        ldr r0, =0x02501400        // addr = 0x02501400

    // write32(addr + 0x04, 0x0);
    mov r1, #0x0               // r1 = 0x0
    str r1, [r0, #0x04]        // 将 r1 存储到 addr + 0x04

    // write32(addr + 0x08, 0xf7);
    mov r1, #0xf7              // r1 = 0xf7
    str r1, [r0, #0x08]        // 将 r1 存储到 addr + 0x08

    // write32(addr + 0x10, 0x0);
    mov r1, #0x0               // r1 = 0x0
    str r1, [r0, #0x10]        // 将 r1 存储到 addr + 0x10

    // val = read32(addr + 0x0c);
    ldr r1, [r0, #0x0c]        // 从 addr + 0x0c 读取 r1

    // val |= (1 << 7);
    orr r1, r1, #(0x80)      // r1 |= (1 << 7)

    // write32(addr + 0x0c, val);
    str r1, [r0, #0x0c]        // 将 r1 存储到 addr + 0x0c

    // write32(addr + 0x00, 0xd & 0xff);
    mov r1, #0xd               // r1 = 0xd
    and r2, r1, #0xff          // r2 = r1 & 0xff
    str r2, [r0]               // 将 r2 存储到 addr + 0x00

    // write32(addr + 0x04, (0xd >> 8) & 0xff);
    mov r2, #0x0               // (0xd >> 8) = 0 (因为 0xd 只有 8 位)
    str r2, [r0, #0x04]        // 将 r2 存储到 addr + 0x04

    // val = read32(addr + 0x0c);
    ldr r1, [r0, #0x0c]        // 从 addr + 0x0c 读取 r1

    // val &= ~(1 << 7);
    bic r1, r1, #(1 << 7)      // r1 &= ~(1 << 7)

    // write32(addr + 0x0c, val);
    str r1, [r0, #0x0c]        // 将 r1 存储到 addr + 0x0c

    // val = read32(addr + 0x0c);
    ldr r1, [r0, #0x0c]        // 从 addr + 0x0c 读取 r1

    // val &= ~0x1f;
    bic r1, r1, #0x1f          // r1 &= ~0x1f

    // val |= (0x3 << 0) | (0 << 2) | (0x0 << 3);
    orr r1, r1, #(0x3 << 0)    // r1 |= (0x3 << 0)

    // write32(addr + 0x0c, val);
    str r1, [r0, #0x0c]        // 将 r1 存储到 addr + 0x0c
    
	/*ldr	r0,=0x01FFFFFF
	ldr	r1,=0x02000098 
	str	r0,[r1]
	ldr	r0,=0x00000000 
	ldr	r1,=0x20000A0
	str	r0,[r1]*/



//loop:
    ldr r3, =0x41
    ldr r0, =0x02501400    // 加载 usart->base 地址到 r0
    mov r1, r0             // 将基地址存储在 r1

wait_for_tx_ready:         // 等待发送缓冲区准备好
    ldr r2, [r1, #0x7c]    // 读取状态寄存器 (偏移 0x7c)
    tst r2, #(0x1 << 1)    // 检查第 1 位 (发送缓冲区是否空)
    beq wait_for_tx_ready  // 如果第 1 位为 0，继续等待

    // 发送字符 c
    str r3, [r1]           // 将字符 r3 写入发送寄存器 (偏移 0x00)

wait_for_tx_complete:      // 等待发送完成
    ldr r2, [r1, #0x7c]    // 读取状态寄存器 (偏移 0x7c)
    tst r2, #(0x1 << 0)    // 检查第 0 位 (发送是否完成)
    bne wait_for_tx_complete // 如果第 0 位为 1，继续等待

//    b loop                  // 返回
    
    mov pc,lr
