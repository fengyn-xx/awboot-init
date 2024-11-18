#include "debug.h"
#include "sunxi_usart.h"
#include "main.h"
#include "board.h"
void sunxi_usart_putc(void *arg, char c);
//void myy_printf((int)fmt,...);
void putint(int pc) {
	
    sunxi_usart_putc(&USART_DBG,'0');
    sunxi_usart_putc(&USART_DBG,'x');
    for (int i = 7; i >= 0; i--) {
    	if(pc == 0){
    		sunxi_usart_putc(&USART_DBG,'z');
    		break;
    	}
    	char tmp = (pc >> (i * 4)) & 0xF;
        sunxi_usart_putc(&USART_DBG,tmp+'0');
    }
	sunxi_usart_putc(&USART_DBG,'\r');
	sunxi_usart_putc(&USART_DBG,'\n');
}


void send_string_via_usart(int a) {
	//putint(a);
	int tmp = a;//+0x18000;
	char* str = (char*)tmp;
	//putint((int)str);
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
