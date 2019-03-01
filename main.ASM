;HHH========================================================================HHH;
;HHH                                                                        HHH;
;HHH                    Multy-frames and num -> str -> num                  HHH;
;HHH                                                                        HHH;
;HHH========================================================================HHH;

.model tiny

;   Machine constants

VIDEO_MEM  = 0b800h
CONS_WIDTH =    80d
LAST_LINE  =    14d

;   Local constants

clr_white = 00Fh ; white

col_width =  13d

.code

extrn makeFrame : proc
extrn printDec  : proc
extrn printBin  : proc
extrn printHex  : proc
extrn getDec    : proc
extrn getBin    : proc
extrn getHex    : proc

extrn var_check : proc

org 100h

start:
    ; clear window
    mov ax, 2h
    int 10h
    
    mov ax, VIDEO_MEM
    mov es, ax
    
    mov di, 0
    
    mov ah, 01h
    int 21h
    
    cmp al, 'd'
    jne not_dec
        mov si, offset s_dec
        jmp ready
not_dec:
    cmp al, 'b'
    jne not_bin
        mov si, offset s_bin
        jmp ready
not_bin:
    mov si, offset s_hex
ready:
    
loo:
    mov ah, 01h
    int 21h
    
    cmp al, 0Dh
    je endloo
    
    mov ds:[si], al
    inc si
    
    jmp loo
endloo:
    mov ds:[si], '$'
    
    ; frame (5, 3) 50x5
    mov ax, 5 ; height
    push ax
    mov ax, 50 ; width
    push ax
    mov ax, 3 ; y
    push ax
    mov ax, 5 ; x
    push ax
    call makeFrame
    add sp, 2 * 4
    
    ; frame (45, 2) 25x4
    mov ax, 4 ; height
    push ax
    mov ax, 25 ; width
    push ax
    mov ax, 2 ; y
    push ax
    mov ax, 45 ; x
    push ax
    call makeFrame
    add sp, 2 * 4

; DEC
    mov ax, offset s_dec
    push ax
    call getDec
    add sp, 2 * 1
    
    push bx
    
    mov ax, 0 ; y
    push ax
    mov ax, col_width ; x
    push ax
    mov ax, bx ; num
    push ax
    call printDec
    add sp, 2 * 3
    
    pop bx
    push bx
    
    mov ax, 0 ; y
    push ax
    mov ax, col_width * 2 ; x
    push ax
    mov ax, bx ; num
    push ax
    call printBin
    add sp, 2 * 3
    
    pop bx
    
    mov ax, 0 ; y
    push ax
    mov ax, col_width * 3 ; x
    push ax
    mov ax, bx ; num
    push ax
    call printHex
    add sp, 2 * 3
    
; BIN
    mov ax, offset s_bin
    push ax
    call getBin
    add sp, 2 * 1
    
    push bx
    
    mov ax, 1 ; y
    push ax
    mov ax, col_width ; x
    push ax
    mov ax, bx ; num
    push ax
    call printDec
    add sp, 2 * 3

    pop bx
    push bx
    
    mov ax, 1 ; y
    push ax
    mov ax, col_width * 2 ; x
    push ax
    mov ax, bx ; num
    push ax
    call printBin
    add sp, 2 * 3
    
    pop bx
    
    mov ax, 1 ; y
    push ax
    mov ax, col_width * 3 ; x
    push ax
    mov ax, bx ; num
    push ax
    call printHex
    add sp, 2 * 3

; HEX
    mov ax, offset s_hex
    push ax
    call getHex
    add sp, 2 * 1
    
    push bx
    
    mov ax, 2 ; y
    push ax
    mov ax, col_width ; x
    push ax
    mov ax, bx ; num
    push ax
    call printDec
    add sp, 2 * 3
    
    pop bx
    push bx
    
    mov ax, 2 ; y
    push ax
    mov ax, col_width * 2 ; x
    push ax
    mov ax, bx ; num
    push ax
    call printBin
    add sp, 2 * 3
    
    pop bx

    mov ax, 2 ; y
    push ax
    mov ax, col_width * 3 ; x
    push ax
    mov ax, bx ; num
    push ax
    call printHex
    add sp, 2 * 3

    mov ax, VIDEO_MEM
    mov es, ax
    
    mov ah, clr_white
    mov cx, 3
    mov di, (col_width + 1) * 2
dec_loop:
    mov al, '('
    mov es:[di], ax
    mov al, '1'
    mov es:[di + 2], ax
    mov al, '0'
    mov es:[di + 4], ax
    mov al, ')'
    mov es:[di + 6], ax
    mov al, '='
    mov es:[di + 8], ax
    
    add di, 2 * CONS_WIDTH
    loop dec_loop
    
    mov ah, clr_white
    mov cx, 3
    mov di, (col_width * 2 + 1) * 2
bin_loop:
    mov al, '('
    mov es:[di], ax
    mov al, '2'
    mov es:[di + 2], ax
    mov al, ')'
    mov es:[di + 4], ax
    mov al, '='
    mov es:[di + 6], ax
    
    add di, 2 * CONS_WIDTH
    loop bin_loop
    
    mov ah, clr_white
    mov cx, 3
    mov di, (col_width * 3 + 1) * 2
hex_loop:
    mov al, '('
    mov es:[di], ax
    mov al, '1'
    mov es:[di + 2], ax
    mov al, '6'
    mov es:[di + 4], ax
    mov al, ')'
    mov es:[di + 6], ax
    
    add di, 2 * CONS_WIDTH
    loop hex_loop
    
    mov ax, 4c00h
    int 21h

.data
s_dec  db '123$'
s_bin  db '11100111$'
s_hex  db 'EDA$'

end start
