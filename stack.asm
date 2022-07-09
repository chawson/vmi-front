;@file {stack.asm}
;call kernel sys_write
%macro write_text 2
mov eax, 4
mov ebx, 1
mov ecx, %1
mov edx, %2
int 0x80
%endmacro

;call kernel sys_exit
%macro exit 0
mov eax, 1
mov ebx, 0
int 0x80
%endmacro

section .bss
    text resb 12; 原始text变量，长度12byte
    o_text resb 2; 用于测试溢出text的部分内存的变量，长度2byte
section .text
    global _start
_start:
    mov eax, 'A'
    mov ecx, 11
    mov edx, text
concat:
    mov [edx], eax
    inc eax
    inc edx
loop concat
    ;向 text末尾写入 \n, 共写入11+1=12个byte
    mov [edx], byte 0xa; 向内存中写直接量时要指明类型

    ;将内存地址溢出 1 位, 根据栈内存的连续性,指向到了o_text的开头
    inc edx
    mov [edx], byte 'L'; 相当于是给o_text的栈内存赋值

    ;mov edx, o_text; 参考性赋值(无实际作用,仅作为证明"栈内存连续性"的充分条件;存在这一句时,执行结果不变)
    inc edx
    mov [edx], byte 0xa;
    
    write_text text,12; A-K\n
    write_text o_text,2; L\n
    
    exit
