11.5
现在的问题是，我把程序写入开发板的0x30000和0x38000两个地方，最终储存的数据都会从0x20000开始储存，全部偏掉了。
读读手册可能可以解决这个问题，手册里0x20000是sram的起始地址，有32kb空间，猜测开发板把程序拷贝到此处执行。
11.6
引入github管理项目。
11.7
打点观察，发现代码的执行地址（pc指针）位置与反汇编代码相符，从0x38000开始;
删去inline关键字后，所有字符串可以正常打印，排除了字符串打印函数的问题;
发现是否注释掉while（1）对函数执行有影响，表现为注释后数据位置为3777c，不注释就在31052，字符串打印停止/卡住是不是因为超出了32kb的界限？
11.8
要定义data段，并在start.S中加上复制data段的代码
11.18
link文件中，增加了虚拟的flash段，并指定为0x420000的位置就可以消除偏移的问题了
24000000,24800000会产生读不出来的问题（非4开头会卡住），44000000,44800000会有烧录不了的问题
