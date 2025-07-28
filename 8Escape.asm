org 0x100

start:
    mov ax, 0x0013
    int 0x10
    
    mov ax, 0xA000
    mov es, ax
    
    call draw_start_screen
    
    mov ah, 0
    int 0x16
    
    mov word [player_x], 160
    mov word [player_y], 100
    
    mov word [exit_x], 300
    mov word [exit_y], 180
    
    call init_enemies

    mov word [enemy_move_counter], 2

game_loop:
    call clear_screen
    
    call draw_exit
    
    call draw_enemies
    
    call draw_player
    
    call check_win
    
    call read_input

    mov ax, [enemy_move_counter]
    cmp ax, 0
    jne .skip_move_enemies
    call move_enemies
    mov word [enemy_move_counter], 2
    jmp .after_move_enemies
.skip_move_enemies:
    dec word [enemy_move_counter]
.after_move_enemies:

    call check_collision
    
    mov cx, 0x0FFF
.wait:
    loop .wait
    
    jmp game_loop
    
end_game:
    mov ax, 0x0003
    int 0x10
    
    mov ax, 0x4C00
    int 0x21

clear_screen:
    pusha
    xor di, di
    mov cx, 320*200
    xor al, al     
    rep stosb
    popa
    ret

draw_start_screen:
    pusha
    mov si, title_msg
    mov cx, title_len
    mov di, (50 * 320) + 100
    call draw_text_black_bg_white_fg
    
    mov si, instr_msg
    mov cx, instr_len
    mov di, (120 * 320) + 80
    call draw_text_black_bg_white_fg
    popa
    ret

draw_player:
    pusha
    mov ax, [player_y]
    mov bx, 320
    mul bx
    add ax, [player_x]
    mov di, ax
    mov al, 1
    call draw_3x3_pixel
    popa
    ret

draw_exit:
    pusha
    mov ax, [exit_y]
    mov bx, 320
    mul bx
    add ax, [exit_x]
    mov di, ax
    mov al, 2
    call draw_3x3_pixel
    popa
    ret

init_enemies:
    pusha
    mov word [enemy1_x], 50
    mov word [enemy1_y], 30
    mov word [enemy2_x], 200
    mov word [enemy2_y], 50
    mov word [enemy3_x], 100
    mov word [enemy3_y], 150
    popa
    ret

draw_enemies:
    pusha
    mov ax, [enemy1_y]
    mov bx, 320
    mul bx
    add ax, [enemy1_x]
    mov di, ax
    mov al, 4
    call draw_3x3_pixel
    
    mov ax, [enemy2_y]
    mov bx, 320
    mul bx
    add ax, [enemy2_x]
    mov di, ax
    mov al, 4
    call draw_3x3_pixel
    
    mov ax, [enemy3_y]
    mov bx, 320
    mul bx
    add ax, [enemy3_x]
    mov di, ax
    mov al, 4
    call draw_3x3_pixel
    popa
    ret

draw_3x3_pixel:
    pusha

    mov ah, al
    mov al, [es:di]
    mov [es:di], ah

    add di, 1
    mov [es:di], ah

    add di, 319
    mov [es:di], ah

    add di, 1
    mov [es:di], ah

    add di, 319
    mov [es:di], ah

    popa
    ret

move_enemies:
    pusha
    
    mov ax, [player_x]
    cmp ax, [enemy1_x]
    jl .enemy1_left
    inc word [enemy1_x]
    jmp .enemy1_y
.enemy1_left:
    dec word [enemy1_x]
.enemy1_y:
    mov ax, [player_y]
    cmp ax, [enemy1_y]
    jl .enemy1_up
    inc word [enemy1_y]
    jmp .enemy2
.enemy1_up:
    dec word [enemy1_y]
    
.enemy2:
    mov ax, [player_x]
    cmp ax, [enemy2_x]
    jl .enemy2_left
    add word [enemy2_x], 1
    jmp .enemy2_y
.enemy2_left:
    sub word [enemy2_x], 1
.enemy2_y:
    mov ax, [player_y]
    cmp ax, [enemy2_y]
    jl .enemy2_up
    add word [enemy2_y], 1
    jmp .enemy3
.enemy2_up:
    sub word [enemy2_y], 1
    
.enemy3:
    mov ax, [rand_seed]
    mov bx, 75
    mul bx
    add ax, 74
    mov [rand_seed], ax

    test al, 1
    jz .enemy3_no_x
    test al, 2
    jz .enemy3_left
    inc word [enemy3_x]
    jmp .enemy3_no_x
.enemy3_left:
    dec word [enemy3_x]
.enemy3_no_x:
    test al, 4
    jz .enemy3_no_y
    test al, 8
    jz .enemy3_up
    inc word [enemy3_y]
    jmp .enemy3_no_y
.enemy3_up:
    dec word [enemy3_y]
.enemy3_no_y:
    popa
    ret

read_input:
    pusha
    mov ah, 0x01
    int 0x16
    jz .no_input
    
    mov ah, 0
    int 0x16
    
    cmp ah, 0x48
    jne .not_up
    cmp word [player_y], 2
    je .no_input
    sub word [player_y], 2
    jmp .no_input
.not_up:
    cmp ah, 0x50
    jne .not_down
    cmp word [player_y], 197
    jae .no_input
    add word [player_y], 2
    jmp .no_input
.not_down:
    cmp ah, 0x4B
    jne .not_left
    cmp word [player_x], 2
    je .no_input
    sub word [player_x], 2
    jmp .no_input
.not_left:
    cmp ah, 0x4D
    jne .no_input
    cmp word [player_x], 317
    jae .no_input
    add word [player_x], 2
.no_input:
    popa
    ret

check_collision:
    pusha
    mov ax, [player_x]
    cmp ax, [enemy1_x]
    jne .check_enemy2
    mov ax, [player_y]
    cmp ax, [enemy1_y]
    je .game_over
    
.check_enemy2:
    mov ax, [player_x]
    cmp ax, [enemy2_x]
    jne .check_enemy3
    mov ax, [player_y]
    cmp ax, [enemy2_y]
    je .game_over
    
.check_enemy3:
    mov ax, [player_x]
    cmp ax, [enemy3_x]
    jne .no_collision
    mov ax, [player_y]
    cmp ax, [enemy3_y]
    je .game_over
    
.no_collision:
    popa
    ret
    
.game_over:
    call clear_screen
    mov si, game_over_msg
    mov cx, game_over_len
    mov di, (90 * 320) + 100
    call draw_text_black_bg_white_fg
    
    mov ah, 0
    int 0x16
    
    jmp end_game

check_win:
    pusha
    mov ax, [player_x]
    cmp ax, [exit_x]
    jne .no_win
    mov ax, [player_y]
    cmp ax, [exit_y]
    jne .no_win
    
    call clear_screen
    mov si, win_msg
    mov cx, win_len
    mov di, (90 * 320) + 100
    call draw_text_black_bg_white_fg
    
    mov ah, 0
    int 0x16
    
    jmp end_game
    
.no_win:
    popa
    ret

draw_text_black_bg_white_fg:
    pusha
    mov ah, 0x0F
.text_loop:
    lodsb
    mov [es:di], al
    inc di
    mov byte [es:di], 0x00
    inc di
    loop .text_loop
    popa
    ret

player_x dw 0
player_y dw 0
exit_x dw 0
exit_y dw 0
enemy1_x dw 0
enemy1_y dw 0
enemy2_x dw 0
enemy2_y dw 0
enemy3_x dw 0
enemy3_y dw 0
rand_seed dw 0xABCD
enemy_move_counter dw 0

title_msg db 'ESCAPE GAME'
title_len equ $-title_msg
instr_msg db 'Use arrow keys to move. Reach the green exit!'
instr_len equ $-instr_msg
game_over_msg db 'GAME OVER!'
game_over_len equ $-game_over_msg
win_msg db 'YOU ESCAPED!'
win_len equ $-win_msg
