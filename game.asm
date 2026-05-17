[BITS 16]
[ORG 0x7E00]

game_start:

    cli
    cld

    xor ax, ax
    mov ds, ax
    mov es, ax

    sti

    call setup_music

    mov ax, 0xA000
    mov es, ax

    xor di, di
    mov al, 1
    mov cx, 64000
    rep stosb

    mov cx, 0xFFFF
.delay:
    loop .delay

    call spawn_new_block

    jmp game_loop

wait_vblank:
    mov dx, 0x3DA
.wait_end:
    in al, dx
    test al, 0x08
    jnz .wait_end
.wait_start:
    in al, dx
    test al, 0x08
    jz .wait_start
    ret

setup_music:
    cli
    xor ax, ax
    mov es, ax
    mov ax, [es:0x0020]
    mov [old_int8], ax
    mov ax, [es:0x0022]
    mov [old_int8+2], ax
    mov word [es:0x0020], music_handler
    mov word [es:0x0022], 0x0000
    sti
    ret

music_handler:
    push ax
    push bx
    push dx
    push ds
    xor ax, ax
    mov ds, ax


    inc word [note_timer]
    cmp word [note_timer], 6   ; music speed
    jl .just_eoi
    mov word [note_timer], 0

    mov bx, [note_index]
    mov ax, [melody + bx]

    cmp ax, 0xFFFF
    jne .check
    mov word [note_index], 0
    mov ax, [melody]
.check:
    cmp ax, 0
    je .sil
    push ax
    mov al, 0xB6
    out 0x43, al
    pop ax
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 0x03
    out 0x61, al
    jmp .done
.sil:
    in al, 0x61
    and al, 0xFC
    out 0x61, al
.done:
    add word [note_index], 2
    jmp .just_eoi

.just_eoi:
    mov al, 0x20
    out 0x20, al
    pop ds
    pop dx
    pop bx
    pop ax
    iret

melody:
    dw 0x0A98, 0x08E9, 0x0713, 0x08E9, 0x0A98, 0x0000, 0x08E9, 0x0713
    dw 0x06AD, 0x0713, 0x08E9, 0x0713, 0x06AD, 0x0000, 0x08E9, 0x07F1
    dw 0x08E9, 0x0713, 0x05F2, 0x0713, 0x08E9, 0x0000, 0x07F1, 0x08E9
    dw 0x0BE4, 0x096F, 0x07F1, 0x096F, 0x0BE4, 0x0000, 0x07F1, 0x05F2
    dw 0x0A98, 0x0713, 0x08E9, 0x0713, 0x0A98, 0x0000, 0x096F, 0x0A98
    dw 0x0D5B, 0x08E9, 0x0A98, 0x08E9, 0x06AD, 0x0000, 0x08E9, 0x0A98
    dw 0x08E9, 0x05F2, 0x0713, 0x05F2, 0x08E9, 0x0000, 0x07F1, 0x08E9
    dw 0x096F, 0x07F1, 0x05F2, 0x07F1, 0x096F, 0x0000, 0x0E20, 0x0A98
    dw 0xFFFF

note_index  dw 0
note_timer  dw 0
old_int8    dd 0

game_loop:

    call check_input
    call apply_gravity
    call draw_everything

    cmp word [game_over_flag], 1
    je system_shutdown

    mov cx, 30000
	
.game_delay:
    loop .game_delay

    jmp game_loop

check_input:

    mov ah, 0x01
    int 0x16
    jz check_input_done

    mov ah, 0x00
    int 0x16

    cmp ah, 0x4B
    je check_left

    cmp ah, 0x4D
    je check_right

    cmp ah, 0x50
    je check_down

    ret

check_left:
    cmp word [current_x], 0
    jle check_input_done

    dec word [current_x]
    call check_collision_shape
    cmp ax, 1
    jne .ok
    inc word [current_x]
.ok:
    ret

check_right:
    cmp word [current_x], 31
    jge check_input_done

    inc word [current_x]
    call check_collision_shape
    cmp ax, 1
    jne .ok
    dec word [current_x]
.ok:
    ret

check_down:
    inc word [current_y]
    call check_collision_shape
    cmp ax, 1
    jne .ok
    dec word [current_y]
    call lock_current_block
.ok:
    ret

check_input_done:
    ret

spawn_new_block:

    in al, 0x40
    xor ah, ah
    mov bx, 7
    xor dx, dx
    div bx
    mov [current_shape], dx

    mov word [current_x], 15
    mov word [current_y], 0

    mov ax, [current_y]
    mov bx, 32
    xor dx, dx
    mul bx
    add ax, 15
    mov si, ax

    cmp byte [board + si], 1
    jne .ok

    mov word [game_over_flag], 1

.ok:
    ret

apply_gravity:

    inc word [gravity_counter]

    cmp word [gravity_counter], 800
    jl gravity_done

    mov word [gravity_counter], 0

    inc word [current_y]

    call check_collision_shape

    cmp ax, 1
    je .do_lock

    jmp gravity_done

.do_lock:
    dec word [current_y]
    call lock_current_block

gravity_done:
    ret

lock_current_block:
    mov ax, [current_shape]
    mov bx, 8
    mul bx
    mov si, shapes
    add si, ax

    mov bx, 4
.lock_block:
    push bx
    push si

    xor ah, ah
    mov al, [si]
    add ax, [current_x]
    push ax

    xor ah, ah
    mov al, [si+1]
    add ax, [current_y]
    push ax

    pop bx
    pop dx

    push dx
    mov ax, bx
    mov bx, 32
    mul bx
    pop dx
    add ax, dx
    mov si, ax

    mov byte [board + si], 1

    pop si
    pop bx
    add si, 2
    dec bx
    jnz .lock_block

    call check_lines
    call spawn_new_block
    ret

draw_everything:

    mov ax, 0x9000
    mov es, ax

    xor di, di
    mov ax, 0x0101
    mov cx, 32000
    rep stosw

    xor cx, cx

draw_y_loop:

    xor dx, dx

draw_x_loop:

    push dx

    mov ax, cx
    mov bx, 32
    xor dx, dx
    mul bx

    pop dx

    add ax, dx
    mov si, ax

    cmp byte [board + si], 1
    jne draw_skip

    push cx
    push dx

    call draw_square_at

    pop dx
    pop cx

draw_skip:

    inc dx
    cmp dx, 32
    jl draw_x_loop

    inc cx
    cmp cx, 20
    jl draw_y_loop

    mov dx, [current_x]
    mov cx, [current_y]
    call draw_shape

    call wait_vblank

    mov ax, 0x9000
    mov ds, ax
    mov ax, 0xA000
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 32000
    rep movsd

    xor ax, ax
    mov ds, ax

    ret

draw_square_at:

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov si, dx

    mov ax, cx
    mov bx, 10
    xor dx, dx
    mul bx

    mov bx, 320
    xor dx, dx
    mul bx
    mov di, ax

    mov ax, si
    mov bx, 10
    xor dx, dx
    mul bx

    add di, ax
    add di, 321

    mov bp, 8

draw_row_loop:

    push di
    mov cx, 8
    mov al, 4
    rep stosb
    pop di
    add di, 320
    dec bp
    jnz draw_row_loop

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

draw_shape:
    mov ax, [current_shape]
    mov bx, 8
    mul bx
    mov si, shapes
    add si, ax

    mov bx, 4
.draw_block:
    push bx
    push si

    xor ah, ah
    mov al, [si]
    add ax, [current_x]
    mov dx, ax

    xor ah, ah
    mov al, [si+1]
    add ax, [current_y]
    mov cx, ax

    call draw_square_at

    pop si
    pop bx
    add si, 2
    dec bx
    jnz .draw_block
    ret

check_collision_shape:
    mov ax, [current_shape]
    mov bx, 8
    mul bx
    mov si, shapes
    add si, ax

    mov bx, 4
.check_block:
    push bx
    push si

    xor ah, ah
    mov al, [si]
    add ax, [current_x]
    push ax

    xor ah, ah
    mov al, [si+1]
    add ax, [current_y]
    push ax

    pop cx
    pop dx

    cmp dx, 0
    jl .collision
    cmp dx, 31
    jg .collision

    cmp cx, 19
    jg .collision

    push dx
    mov ax, cx
    mov bx, 32
    mul bx
    pop dx
    add ax, dx
    mov si, ax

    cmp byte [board + si], 1
    je .collision

    pop si
    pop bx
    add si, 2
    dec bx
    jnz .check_block

    xor ax, ax
    jmp .done

.collision:
    pop si
    pop bx
    mov ax, 1

.done:
    ret

check_lines:
    mov cx, 19

.check_row:
    push cx

    mov ax, cx
    mov bx, 32
    mul bx
    mov si, ax

    mov dx, 32
.check_cell:
    cmp byte [board + si], 1
    jne .row_not_full
    inc si
    dec dx
    jnz .check_cell

    mov ax, cx
    mov bx, 32
    mul bx
    mov si, ax

    push cx
.shift_down:
    cmp cx, 0
    je .clear_top

    mov ax, cx
    dec ax
    mov bx, 32
    mul bx
    mov di, ax

    mov ax, cx
    mov bx, 32
    mul bx
    mov si, ax

    push cx
    mov cx, 32
.copy_cell:
    mov al, [board + di]
    mov [board + si], al
    inc si
    inc di
    loop .copy_cell
    pop cx

    dec cx
    jmp .shift_down

.clear_top:
    mov si, 0
    mov cx, 32
.clear_cell:
    mov byte [board + si], 0
    inc si
    loop .clear_cell

    pop cx
    jmp .check_row_again

.row_not_full:
    pop cx
    dec cx
    cmp cx, 0
    jge .check_row
    ret

.check_row_again:
    pop cx
    jmp .check_row

system_shutdown:
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    cli
    xor ax, ax
    mov es, ax
    mov ax, [old_int8]
    mov [es:0x0020], ax
    mov ax, [old_int8+2]
    mov [es:0x0022], ax
    sti

    mov ax, 0xA000
    mov es, ax

    mov bx, 60
.flash_loop:
    push bx

    xor di, di
    mov cx, 32000
    mov al, [flash_color]
    rep stosb
    mov cx, 32000
    mov al, [flash_color2]
    rep stosb

    mov al, [flash_color]
    mov ah, [flash_color2]
    mov [flash_color], ah
    mov [flash_color2], al

    mov cx, 5000
.delay:
    loop .delay

    pop bx
    dec bx
    jnz .flash_loop

    mov ax, 0x0003
    int 0x10

    mov ah, 0x13
    mov al, 0x01
    mov bh, 0x00
    mov bl, 0x4F
    mov cx, 9
    mov dh, 12
    mov dl, 35
    push cs
    pop es
    mov bp, gameover_msg
    int 0x10

    mov cx, 4
.wait:
    push cx
    mov ah, 0x86
    mov cx, 0x000F
    mov dx, 0x4240
    int 0x15
    pop cx
    loop .wait

    cli
    jmp 0xFFFF:0x0000

flash_color  db 2
flash_color2 db 5
font_seg     dw 0
font_ptr     dw 0

gameover_msg db 'GAME OVER'

current_shape    dw 0
current_rotation dw 0

shapes:
    db 0,0, 1,0, 2,0, 3,0
    db 0,0, 0,1, 0,2, 0,3
    db 0,0, 1,0, 0,1, 1,1
    db 0,0, 1,0, 2,0, 1,1
    db 0,0, 0,1, 1,1, 0,2
    db 0,0, 0,1, 0,2, 1,2
    db 1,0, 1,1, 0,2, 1,2

current_x       dw 15
current_y       dw 0
gravity_counter dw 0
game_over_flag  dw 0
board           times 640 db 0
