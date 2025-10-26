[BITS 64]

global _start

extern itoa

section .rodata
    DNS_PORT equ 53
    MAX_DNS_PACKET_SIZE equ 512
    AF_INET equ 2
    DNS_HEADER_SIZE equ 12
section .data
    dnsAnswer db "Dns answer for "
    website db "csgoempire.com", 0
    dnsAnswerLength equ $-dnsAnswer
    websiteLength equ $-website
    DNS_IP dd 0x08080808 ; google dns server
    socketError db "Socket error", 10
    socketErrorLength equ $-socketError
    sendToError db "Sendto syscall error", 10
    sendToErrorLength equ $-sendToError
    addr_len dq 16
    recvFromError db "Receive from error or no data received", 10
    recvFromErrorLength equ $-recvFromError
    noAnswersReceivedError db "No answers received from dns", 10
    noAnswersReceivedErrorLength equ $-noAnswersReceivedError
    noQueryTypeA db "No query type A in the response", 10
    noQueryTypeALength equ $-noQueryTypeA
    noIpV4CorrectLength db "No IpV4 correct length in response", 10
    noIpV4CorrectLengthLength equ $-noIpV4CorrectLength
    

section .bss
    websiteRaw reso 1 ;maximumw website length = 16 - 2 for length and \0 = 14 bytes in this example
    send_buff reso 64
    receive_buff reso 64
    dns_server_addr resb 16; 16 bytes for sockaddr_in struct
    dns_header:
        resw 0 ; transaction id
        resw 0 ;flags
        resw 0 ; number of questions
        resw 0 ;number of answer RRs
        resw 0 ;number of authority RRs
        resw 0 ; number of additional rrs
    number resw 1
    r_type resw 1
    rdlength resw 1
    ipv4:
        resb 1
        resb 1
        resb 1
        resb 1
    ipv4ascii resb 3*4+3+1 ; 1 for \n


section .text
    _start:
        call get_dns_ip
    ; we expect a pointer to a first char of writable string passed in rdi reading from rsi, must be null terminated
    convert_to_dns_format:
        push rcx
        push rdx
        push rbx
        ;counters: 
        mov rax, 0; i
        mov rcx, 1; j
        ;current len
        mov rdx, 0
        .main_loop:
            mov bl,byte  [rsi+rax]
            cmp bl, 0
            je .end_conversion
            cmp bl, '.'
            je .dot_found
            mov byte [rdi+rcx], bl
            inc rcx
            inc rax
            inc rdx
            jmp .main_loop
        .write_length:
            mov rbx, rcx
            sub rbx, rdx
            sub rbx, 1
            mov byte [rdi+rbx], dl
            xor rdx, rdx
            ret
        .dot_found:
            call .write_length
            inc rax
            inc rcx
            jmp .main_loop
        .end_conversion:
            call .write_length
            mov byte [rdi+rcx], 0x0
            inc rcx
            mov rax, rcx
            pop rbx
            pop rdx
            pop rcx
            ret

    ;pointer in rdi
    advance_pointer_past_name:
        mov rsi, rdi
        mov al, byte [rdi]
        and al, 0xC0
        cmp al, 0xC0
        je .return2
        .checkForZero:
            cmp byte [rdi], 0x00
            jne .noZero
            jmp .continue
        .noZero:
            mov bl, byte [rdi]
            inc bl
            add rdi, rbx
            jmp .checkForZero
        .continue:
            inc rdi     
            mov rax, rdi
            sub rax, rsi
            ret
        .return2:
            mov rax, 2
            ret
    ;argument in rdi
    htons:
        mov ax, di       
        xchg ah, al  
        ret
    ntohs:
        mov ax, di   
        xchg ah, al  
        ret
        
    get_dns_ip:
        mov word [dns_server_addr], AF_INET        ; sin_family
        mov rdi, DNS_PORT
        call htons
        mov word [dns_server_addr+2], ax       
        mov edi, [DNS_IP]
        mov dword [dns_server_addr+4], edi        
        mov qword [dns_server_addr+8], 0         



        mov rdi, 0x1234
        call htons
        mov word [send_buff], ax
        mov rdi, 0x100
        call htons
        mov word [send_buff+2], ax
        mov rdi, 0x1
        call htons 
        mov word [send_buff+4], ax
        mov rdi, 0
        call htons
        mov word [send_buff+6], ax
        lea rdi, [send_buff+DNS_HEADER_SIZE]
        lea rsi, [website]
        call convert_to_dns_format
        mov r11, rax ;qname
        lea r10, [rdi+rax]
        mov rdi, 0x1
        call htons
        mov word [r10], ax ;qtype
        add r10, 2
        mov word [r10], ax ;qclass
        add r11, DNS_HEADER_SIZE
        add r11, 4 ; 4 bytes for qtype, qclass
        
        mov r14, r11; query length in r14 q
        xor r11, r11


        mov rax, 41 ;socket
        mov rdi, 2 ;AF_INET
        mov rsi, 2; SOCK_DGRAM
        mov rdx, 0 ;protocol - udp
        syscall
        mov r15, rax ; sockfd in r15
        cmp rax, 0
        jl socket_error

        mov rax, 44          
        mov rdi, r15        
        lea rsi, [send_buff]   
        mov rdx, r14   
        xor r10, r10            ; flags 
        lea r8, [dns_server_addr] 
        mov r9, qword [addr_len]              ; addrlen
        syscall
        
        cmp rax, 0
        jl sendto_err

        mov rax, 45 ;recvfrom
        mov rdi, r15 
        mov rsi, receive_buff
        mov rdx, MAX_DNS_PACKET_SIZE 
        mov r10, 0
        lea r8, [dns_server_addr]
        lea r9, [addr_len]
        syscall

        cmp rax, 0
        jle recvfrom_err

        mov rax, 3 ;closing socket
        mov rdi, r15
        syscall

        mov di, word [receive_buff+6]
        call ntohs
        cmp ax, 0
        je no_answers_received


        lea rdi, [receive_buff]
        add rdi, r14 ;advanced to the ip section
        
        call advance_pointer_past_name
        add rdi, rax

        mov rcx, rdi

        mov rdi, [rcx]
        call ntohs
        mov word [r_type], ax

        add rcx, 2; past r_type

        add rcx, 2 ; skip class
        add rcx, 4 ; skip TTL

        mov rdi, [rcx]
        call ntohs
        mov word [rdlength], ax
        add rcx, 2

        cmp word [r_type], 1 ; check for type a
        jne no_query_type_a

        cmp word [rdlength], 4 ; check for ip4 ( 4 bytes )
        jne no_ipv4

        mov rdi, ipv4
        lea rsi, [rcx]
        mov rcx, 4
        rep movsb

        call print_ipv4
        
        jmp exit

    no_query_type_a:
        mov rax, 1
        mov rdi, 1
        mov rsi, noQueryTypeA
        mov rdx, noQueryTypeALength
        syscall
        jmp exit
    no_ipv4:
        mov rax, 1
        mov rdi, 1
        mov rsi, noIpV4CorrectLength
        mov rdx, noIpV4CorrectLengthLength
        syscall
        jmp exit

    no_answers_received:
        mov rax, 1
        mov rdi, 1
        mov rsi, noAnswersReceivedError
        mov rdx, noAnswersReceivedErrorLength
        syscall
        jmp exit
    recvfrom_err:
        mov rax, 1
        mov rdi, 1
        mov rsi, recvFromError
        mov rdx, recvFromErrorLength
        syscall
        jmp exit
    sendto_err:
        mov rax, 1
        mov rdi, 1
        mov rsi, sendToError
        mov rdx, sendToErrorLength
        syscall
        jmp exit

    socket_error:
        mov rax, 1
        mov rdi, 1
        mov rsi, socketError
        mov rdx, socketErrorLength
        syscall
        jmp exit
    exit:
        mov rax, 60
        mov rdi, r14
        syscall
    print_ipv4:
        mov r8, ipv4ascii
        xor rcx, rcx
        .main_loop:
            
            movzx rdi, byte [ipv4+rcx]
            mov rsi, r8
            call itoa
            add r8, rax
            
            cmp rcx, 3
            je .done
            mov byte [r8], '.'
            inc r8
            inc rcx
            jmp .main_loop
        
        .done:
            mov byte [r8], 10
            inc r8
            mov rdx, r8
            sub rdx, ipv4ascii
            mov rax, 1
            mov rdi, 1
            mov rsi, ipv4ascii
            syscall
