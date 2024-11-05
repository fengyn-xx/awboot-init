#include "debug.h"
#include "sunxi_usart.h"
#include "main.h"
#include "board.h"
void sunxi_usart_putc(void *arg, char c);
//void myy_printf((int)fmt,...);
void putint(int a) {
	
	//p += 0x1000;
	//int a = *p;
    if (a == 0) {
        sunxi_usart_putc(&USART_DBG, '0');
        sunxi_usart_putc(&USART_DBG, '\r');
        sunxi_usart_putc(&USART_DBG, '\n');
        return;
    }
    
    if (a < 0) {
        sunxi_usart_putc(&USART_DBG, '-');
        a = -a; // 转换为正数
    }
    
    unsigned int count = 1;
    unsigned int tmp = a;
    
    // 计算数字位数
    while (tmp >= 10) {
        tmp /= 10;
        count *= 10;
    }
    
    // 输出数字
    while (count > 0) {
        unsigned int digit = a / count;  // 获取当前位
        sunxi_usart_putc(&USART_DBG, '0' + digit);
        a -= digit * count;      // 减去当前位的值
        count /= 10;             // 移动到下一位
    }
    
    sunxi_usart_putc(&USART_DBG, '\r');
    sunxi_usart_putc(&USART_DBG, '\n');
}


static inline void send_string_via_usart(int a) {

	int tmp = a;//+0x10000;
	char* str = (char*)tmp;
	for(int i = 0;i<100;i++){
		if(str[i] == '\0')break;
		sunxi_usart_putc(&USART_DBG,str[i]);
	}
}
void message(const char *fmt,...)
{	
	send_string_via_usart((int)fmt);
	/*va_list args;
	va_start(args, (int)fmt);
	myy_printf((int)fmt,args);
	//xvformat(sunxi_usart_putc, &USART_DBG, fmt, args);//if have this row,last row exed;but dont have this row,last row dont exec
	va_end(args);*/
	
	
}
