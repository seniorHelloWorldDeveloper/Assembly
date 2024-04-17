global start

extern printf
extern gets
extern strlen
extern strcmp
extern strcpy

%define SIZE_OF_STRING 50
%define SIZE_OF_ARRAY 10

section .data
    formatString db "%s", 0
    formatLongestString db "Longest: %s", 10, 0
    noStringWereEntered db 10, "No string were entered", 10, 0
    formatShortestString db "Shortest: %s", 10, 0
    enterNames db "Enter 10 names: ", 10, 0
    formatFirst db "First: %s", 10, 0
    formatInt db "%d", 10, 0
    first db "zzzzzzzzzzzzzzzzzzzzzz", 0
    last db "", 0
    formatLast db "Last: %s", 10, 0
    
section .bss
    array resb SIZE_OF_STRING*SIZE_OF_ARRAY
section .text
    start:
        push rbp
        mov rbp, rsp
        sub rsp, 32
        mov rcx, formatString
        mov rdx, enterNames
        call printf
        xor rax, rax
        xor rcx, rcx
        xor rdx, rdx
        xor rbx, rbx
        jmp .getWords

        .getWords:
            cmp rbx, SIZE_OF_ARRAY
            je .clearLongest

            imul rsi, rbx, SIZE_OF_STRING

            lea rdi, byte [array+rsi]

            mov rcx, rdi
            call gets
            
            inc rbx
            jmp .getWords

        .clearLongest:
            add rsp, 32
            leave
            push rbp
            mov rbp, rsp
            sub rsp, 16

            xor rsi, rsi
            xor rdi, rdi
            xor rbx, rbx
            mov qword [rbp-8], -1 ;longest index
            mov qword [rbp-16], 0 ;max length
            jmp .checkForLongest

        .checkForLongest:
            cmp rbx, SIZE_OF_ARRAY
            je .printfLongestCheck
            imul rsi, rbx, SIZE_OF_STRING
            lea rcx, byte [array+rsi]
            call strlen ;rax - length of string
            mov rdi, rax
            cmp rdi, qword [rbp-16]
            jg .setIndex
            inc rbx
            jmp .checkForLongest
            ret
        .setIndex:
            mov [rbp-8], rbx
            mov [rbp-16], rdi
            jmp .checkForLongest
        .printfLongestCheck:
            cmp qword [rbp-8], -1
            jne .printLongest
            je .noStrings
            
            ret
        .printLongest:
            sub rsp, 32
            xor rbx, rbx

            mov rbx, qword [rbp-8]
            xor rsi, rsi
            imul rsi, rbx, SIZE_OF_STRING
            lea rcx, byte [formatLongestString]
            lea rdx, byte [array+rsi]
            call printf
            add rsp, 32+16
            leave
            jmp .clearShortest
            ret

        .noStrings:
            sub rsp, 32
            mov rcx, formatString
            mov rdx, noStringWereEntered
            call printf
            add rsp, 32+16
            leave
            ret

        .clearShortest:
            push rbp
            mov rbp, rsp
            sub rsp, 16
            xor rbx, rbx
            xor rsi, rsi
            xor rax, rax
            xor rdi, rdi
            mov qword [rbp-8], -1 ;shortest index
            mov qword [rbp-16], 51 ;min length
            jmp .checkForShortest
        

        .checkForShortest:
            cmp rbx, SIZE_OF_ARRAY
            je .printfShortestCheck
            imul rsi, rbx, SIZE_OF_STRING
            lea rcx, byte [array+rsi]
            call strlen ;rax - length of string
            mov rdi, rax
            cmp rdi, qword [rbp-16]
            jl .setIndexShortest
            inc rbx
            jmp .checkForShortest
            ret

        .setIndexShortest:
            mov [rbp-8], rbx
            mov [rbp-16], rdi
            jmp .checkForShortest

        .printfShortestCheck:
            cmp qword [rbp-8], -1
            jne .printShortest
            je .noStrings
            
            ret
        .printShortest:
            sub rsp, 32
            xor rbx, rbx

            mov rbx, qword [rbp-8]
            xor rsi, rsi
            imul rsi, rbx, SIZE_OF_STRING
            lea rcx, byte [formatShortestString]
            lea rdx, byte [array+rsi]
            call printf
            add rsp, 32+16
            leave
            jmp .setAlphabet
            ret

        .setAlphabet:
            push rbp
            mov rbp, rsp
            sub rsp, 32
            xor rbx, rbx
            xor rsi, rsi
            xor rdi, rdi
            xor rax, rax
            lea rcx, [first]
            lea rdx, byte [array]
            call strcpy
            jmp .checkForAlphabet
        .checkForAlphabet:
            cmp rbx, SIZE_OF_ARRAY
            je .printFirstAndLast
            
            imul rsi, rbx, SIZE_OF_STRING

            lea rcx, byte [array+rsi]
            mov rdx, first
            call strcmp
            cmp rax, 0
            jl .cpyFirst
            lea rcx, byte [array+rsi]
            mov rdx, last
            call strcmp
            cmp rax, 0
            jg .cpyLast
            inc rbx
            jmp .checkForAlphabet

        .cpyFirst:
            mov rcx, first
            lea rdx, byte [array+rsi]
            call strcpy
            jmp .checkForAlphabet
        .printFirstAndLast:
            mov rcx, formatFirst
            mov rdx, first
            call printf
            mov rcx, formatFirst
            mov rdx, last
            call printf
            add rsp, 38
            leave
            ret
        .cpyLast:
            mov rcx, last
            lea rdx, byte [array+rsi]
            call strcpy
            jmp .checkForAlphabet