11.6
现在的问题是，我把程序写入开发板的0x30000和0x38000两个地方，最终储存的数据都会从0x20000开始储存，全部偏掉了。
读读手册可能可以解决这个问题，手册里0x20000是sram的起始地址，有32kb空间，猜测开发板把程序拷贝到此处执行。
