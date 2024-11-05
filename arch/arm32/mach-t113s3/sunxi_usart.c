#include <stdarg.h>
#include "io.h"
#include "main.h"
#include "sunxi_usart.h"
#include "reg-ccu.h"

void sunxi_usart_init(sunxi_usart_t *usart)
{
	uint32_t addr;
	uint32_t val;

	/* Config usart TXD and RXD pins */
	sunxi_gpio_init(usart->gpio_tx.pin, usart->gpio_tx.mux);
	sunxi_gpio_init(usart->gpio_rx.pin, usart->gpio_rx.mux);

	/* Open the clock gate for usart */
	addr = T113_CCU_BASE + CCU_USART_BGR_REG;
	val	 = read32(addr);
	val |= 1 << usart->id;
	write32(addr, val);

	/* Deassert USART reset */
	addr = T113_CCU_BASE + CCU_USART_BGR_REG;
	val	 = read32(addr);
	val |= 1 << (16 + usart->id);
	write32(addr, val);

	/* Config USART to 115200-8-1-0 */
	addr = usart->base;
	write32(addr + 0x04, 0x0);
	write32(addr + 0x08, 0xf7);
	write32(addr + 0x10, 0x0);
	val = read32(addr + 0x0c);
	val |= (1 << 7);
	write32(addr + 0x0c, val);
	write32(addr + 0x00, 0xd & 0xff);
	write32(addr + 0x04, (0xd >> 8) & 0xff);
	val = read32(addr + 0x0c);
	val &= ~(1 << 7);
	write32(addr + 0x0c, val);
	val = read32(addr + 0x0c);
	val &= ~0x1f;
	val |= (0x3 << 0) | (0 << 2) | (0x0 << 3);
	write32(addr + 0x0c, val);
}

void sunxi_usart_putc(void *arg,char c)
{
	/*sunxi_usart_t *usart = (sunxi_usart_t *)arg;
	while ((read32(usart->base + 0x7c) & (0x1 << 1)) == 0)
		;
	write32(usart->base + 0x00, c);
	while ((read32(usart->base + 0x7c) & (0x1 << 0)) == 1)
		;*/
		//sunxi_usart_t *usart = (sunxi_usart_t *)arg;
		uint32_t status;
		//uint32_t usart_base = usart->base;
		uint32_t usart_base = 0x02501400;

    // 等待发送缓冲区准备好
    do {
        __asm__ volatile (
            "ldr %[status], [%[base], #0x7C] \n"  // 读取状态寄存器 (偏移 0x7C)
            "tst %[status], #(1 << 1) \n"         // 检查第 1 位 (发送缓冲区是否空)
            : [status] "=r" (status)              // 输出
            : [base] "r" (usart_base)             // 输入
        );
    } while ((status & (1 << 1)) == 0);

    // 发送字符
    __asm__ volatile (
        "str %[ch], [%[base]] \n"  // 将字符 c 写入发送寄存器 (偏移 0x00)
        :
        : [ch] "r" ((uint32_t)c), [base] "r" (usart_base)
    );

    // 等待发送完成
    do {
        __asm__ volatile (
            "ldr %[status], [%[base], #0x7C] \n"  // 读取状态寄存器 (偏移 0x7C)
            "tst %[status], #(1 << 0) \n"         // 检查第 0 位 (发送是否完成)
            : [status] "=r" (status)              // 输出
            : [base] "r" (usart_base)             // 输入
        );
    } while ((status & (1 << 0)) != 0);
}
