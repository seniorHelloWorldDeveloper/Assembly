[BITS 64]

global itoa
section .text
    itoa:

        ;number in rdi, buffer in rsi
        push rcx
        push rbx
        push r10
        push r11
        push r12
        push rdx
        xor rcx, rcx ;i
        mov rbx, 10 ; just 10
        cmp rdi, 0
        je .equal_zero
        .no_zero:
            mov rax, rdi
            xor rdx, rdx
            div rbx
            add dl, 48
            mov byte [rsi+rcx], dl
            inc rcx
            mov rdi, rax
            cmp rdi, 0
            jg .no_zero
            jmp .start_reverse


        .equal_zero:
            mov byte [rsi+rcx], 48 ; 0 char in ascii
            inc rcx
            
        .start_reverse:
            mov rdx, 0 ; start
            mov r10, rcx; end
            dec r10

        .convert_loop:
            cmp rdx, r10
            jge .append_zero
            mov r11b, byte [rsi+rdx]
            mov r12b, byte [rsi+r10]
            mov byte [rsi+rdx], r12b
            mov byte [rsi+r10], r11b
            inc rdx
            dec r10
            jmp .convert_loop

        .append_zero:
            mov byte [rsi+rcx], 0
            pop rdx
            pop r12
            pop r11
            pop r10
            pop rbx
            pop rcx
            ret