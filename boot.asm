[BITS 16]
[ORG 0x7C00]
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov [boot_drive], dl

    ; TEXT MODE
    mov ax, 0x0003
    int 0x10

    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    call fill_left_black

    call fill_right_red

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 10
    mov dl, 10
    int 0x10

    ; Typing
    call intro_animation

    mov cx, 2
.wait_loop:
    push cx
    mov ah, 0x86
    mov cx, 0x000F
    mov dx, 0x4240
    int 0x15
    pop cx
    loop .wait_loop

    ; VGA MODE
    mov ax, 0x0013
    int 0x10

    ; LOAD GAME
    xor ax, ax
    mov es, ax
    mov bx, 0x7E00
    mov ah, 0x02
    mov al, 10
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    jmp 0x0000:0x7E00

fill_left_black:
    mov ah, 0x06
    mov al, 0x00       
    mov bh, 0x10        

    mov bh, 0x40     
    mov ch, 0       
    mov cl, 0          
    mov dh, 24     
    mov dl, 39       
    int 0x10
    ret

fill_right_red:
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x40    
    mov ch, 0
    mov cl, 40          
    mov dh, 24
    mov dl, 79
    int 0x10
    ret


intro_animation:
    mov si, msg
    mov [char_col], byte 10   

.next_char:
    lodsb
    cmp al, 0
    je .done

    mov [cur_char], al

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 10
    mov dl, [char_col]
    int 0x10

    mov ah, 0x09
    mov al, [cur_char]
    mov bh, 0x00
    mov bl, 0x1F       
    mov cx, 1
    int 0x10


    inc byte [char_col]


    call char_delay

    jmp .next_char
.done:
    ret

char_delay:
    push cx
    push ax
    mov cx, 0x0000      
.outer:
    mov ax, 0x200        ; (~typing speed)
.inner:
    dec ax
    jnz .inner
    loop .outer
    pop ax
    pop cx
    ret


disk_error:
    mov ax, 0x0003
    int 0x10
    mov si, err
.print2:
    lodsb
    cmp al, 0
    je .hang
    mov ah, 0x0E
    mov bl, 0x0C
    int 0x10
    jmp .print2
.hang:
    cli
    hlt
    jmp .hang


boot_drive  db 0
char_col    db 0
cur_char    db 0
msg db "You have been hacked by KRYNZ.exe - Alex Cybersecurity", 0
err db "DISK ERROR - Cannot load", 0

times 510-($-$$) db 0
dw 0xAA55
