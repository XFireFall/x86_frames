.model tiny

;   Machine constants

VIDEO_MEM  = 0b800h
CONS_WIDTH =    80d
LAST_LINE  =    14d

;   Local constants

chr_fill  = 0B0h
chr_empty = 000h

clr_white = 00Fh ; white

tbl_IN    = 010h ; blue
txt_IN    = clr_white
tbl_BD    = 030h ; cyan
txt_BD    = clr_white

tbl_LU    = 0c9h
tbl_RU    = 'X' ; 0bbh `
tbl_LD    = 0c8h
tbl_RD    = 0bch

tbl_H     = 0cdh
tbl_V     = 0bah

num_CLR   =  02h ; green
col_width =  13d

.code

public makeFrame
public printDec
public printBin
public printHex
public getDec
public getBin
public getHex

public var_check
var_check proc _a, _b, _c
    push bp
    mov bp, sp
    
    ; es -> video memory
    mov ax, VIDEO_MEM
    mov es, ax
    
    mov ax, _a
    mov ah, 04Eh
    
    stosw
    
    pop bp
    ret
    endp

;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   makeFrame                     HHH
;HHH - make a simple frame with standart messages    HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > x       (position x)          HHH
;HHH                   y       (position y)          HHH
;HHH                   width   (frame size x)        HHH
;HHH                   height  (frame size y)        HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          SI, DI, ES                             HHH
;HHH                                                 HHH
;HHH=================================================HHH

makeFrame proc
    push bp
    mov bp, sp
    
    ;      x = [bp + 4]
    ;      y = [bp + 6]
    ;  width = [bp + 8]
    ; height = [bp + 10]
    
    ;---------------------------------------------
    
; FILLING

    ; es -> video memory
    mov ax, VIDEO_MEM
    mov es, ax

    ; di -> LU corner (in)
        mov ax, [bp + 6]    ;
        inc ax              ;
        mov dx, CONS_WIDTH  ; ax = (y + 1) * CONS_WIDTH
        mul dx              ;
        
        add ax, [bp + 4]    ;
        inc ax              ; ax += x + 1
        
        shl ax, 1           ; ax *= 2
    mov di, ax
    
    ; si <=> current y position
    mov si, 0   
    
    ; cx = width - 2
    mov cx, [bp + 8]
    sub cx, 2
    
    ; bx = height - 2
    mov bx, [bp + 10]
    sub bx, 2
    
    ; ax = filler symbol
    mov al, chr_fill
    mov ah, tbl_IN + txt_IN
    
    cld
newline:
    stosw
    loop newline
    ; cx == 0 <=> end of line
    
    ; di -> next line
    ; si++ as new line
        mov dx, CONS_WIDTH + 2
        sub dx, [bp + 8]
        shl dx, 1
    add di, dx
    inc si
    
    ; cx = width - 2 (restore)
    mov cx, [bp + 8]
    sub cx, 2
    
    cmp si, bx
    jne newline
    ; si == bx <=> end of lines

; UP & DOWN LINES
    
    ; di = LU corner + 1x
        mov ax, [bp + 6]    ;
        mov dx, CONS_WIDTH  ; ax = y * CONS_WIDTH
        mul dx              ;
        
        add ax, [bp + 4]    ;
        inc ax              ; ax += x + 1
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = (y * CONS_WIDTH + x + 1) * 2
        
    ; dx - displacement to down line
        mov ax, [bp + 10]   ;
        dec ax              ;
        mov dx, CONS_WIDTH  ; ax = (height - 1) * CONS_WIDTH
        mul dx              ;
        
        shl ax, 1           ; ax *= 2
    mov dx, ax              ; res: dx = (height - 1) * CONS_WIDTH * 2
    
    ; cx = width - 2
    mov cx, [bp + 8]
    sub cx, 2
    
    ; ax = table horyzontal symbol
    mov al, tbl_H
    mov ah, tbl_BD + txt_BD
    
inc_x:
    mov es:[di], ax ; up line
    add di, dx
    mov es:[di], ax ; down line
    sub di, dx
    
    add di, 2
    loop inc_x
    ; cx == 0 <=> end of line

; LEFT & RIGHT LINES

    ; di -> LU corner + 1y
        mov ax, [bp + 6]    ;
        inc ax              ;
        mov dx, CONS_WIDTH  ; ax = (y + 1) * CONS_WIDTH
        mul dx              ;
        
        add ax, [bp + 4]    ; ax += x
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = ((y + 1) * CONS_WIDTH + x) * 2
    
    ; dx - displacement to right line
        mov ax, [bp + 8]    ;
        dec ax              ; ax = width - 1
        
        shl ax, 1           ; ax *= 2
    mov dx, ax              ; res: dx = (width - 1) * 2
    
    ; cx = height - 2
    mov cx, [bp + 10]
    sub cx, 2
    
    ; ax = table vertical symbol
    mov al, tbl_V
    mov ah, tbl_BD + txt_BD
    
inc_y:
    mov es:[di], ax ; left line
    add di, dx
    mov es:[di], ax ; right line
    sub di, dx
    
    add di, CONS_WIDTH * 2
    loop inc_y
    ; cx == 0 <=> end of column

; CORNERS
    
    ; di -> LU corner
        mov ax, [bp + 6]    ;
        mov dx, CONS_WIDTH  ; ax = y * CONS_WIDTH
        mul dx              ;
        
        add ax, [bp + 4]    ; ax += x
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = (y * CONS_WIDTH + x) * 2
    
    ; ax = LU corner symbol
    mov al, tbl_LU
    mov ah, tbl_BD + txt_BD
    
    mov es:[di], ax
    
    
    ; di -> RU corner
        mov ax, [bp + 8]
        dec ax
        shl ax, 1
    add di, ax              ; res: di = (y * CONS_WIDTH + x + width - 1) * 2
    
    ; ax = LU corner symbol
    mov al, tbl_RU
    mov ah, tbl_BD + txt_BD
    
    mov es:[di], ax
    
    
    ; di -> RD corner
        mov ax, [bp + 10]
        dec ax
        mov dx, CONS_WIDTH
        mul dx
        shl ax, 1
    add di, ax              ; res: di = ((y + height - 1) * CONS_WIDTH + x + width - 1) * 2
    
    ; ax = RD corner symbol
    mov al, tbl_RD
    mov ah, tbl_BD + txt_BD
    
    mov es:[di], ax
    
    
    ; di -> LD corner
        mov ax, [bp + 8]
        dec ax
        shl ax, 1
    sub di, ax              ; res: di = ((y + height - 1) * CONS_WIDTH + x) * 2
    
    ; ax = LD corner symbol
    mov al, tbl_LD
    mov ah, tbl_BD + txt_BD
    
    mov es:[di], ax

; PRINTING MESSAGES

    ; di -> LU corner + 1x + 1y
        mov ax, [bp + 6]    ;
        inc ax              ;
        mov dx, CONS_WIDTH  ; ax = (y + 1) * CONS_WIDTH
        mul dx              ;
        
        add ax, [bp + 4]    ;
        inc ax              ; ax += x + 1
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = ((y + 1) * CONS_WIDTH + x + 1) * 2
    ; backup di
    push di
    
    ; si -> message #1
    mov si, offset msg
    
    ; ah = message color 
    mov ah, tbl_IN + txt_IN
    
    ; print_msg( ax, si, di )
    call print_msg

    
    ; load di from backup
    pop di
    
    ; di -> LD corner + 1x - 1y
        mov ax, [bp + 10]   ;
        sub ax, 3           ;
        mov dx, CONS_WIDTH  ; ax = (height - 3) * CONS_WIDTH
        mul dx              ;
        
        shl ax, 1           ; ax *= 2
    add di, ax              ; res: di = ((y + height - 2) * CONS_WIDTH + x + 1) * 2
    
    ; si -> message #2
    mov si, offset msg2
    
    ; ax = message color
    mov ah, tbl_IN + txt_IN
    
    ; print_msg( ax, si, di )
    call print_msg
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp

;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   printDec                      HHH
;HHH - print a number as decimal                     HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > num  (the number to print)    HHH
;HHH                   x    (position x)             HHH
;HHH                   y    (position y)             HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          DI, ES                                 HHH
;HHH                                                 HHH
;HHH WARNING: reverse printing                       HHH
;HHH                                                 HHH
;HHH=================================================HHH

printDec proc
    push bp
    mov bp, sp
    
    ; num = [bp + 4]
    ;   x = [bp + 6]
    ;   y = [bp + 8]
    
    ;---------------------------------------------
    
    std
    
    ; es -> video memory
    mov ax, VIDEO_MEM
    mov es, ax
    
    ; di -> (x, y)
        mov ax, [bp + 8]    ;
        mov bx, CONS_WIDTH  ; ax = y * CONS_WIDTH
        mul bx              ;
        
        add ax, [bp + 6]    ; ax += x
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = (y * CONS_WIDTH + 2) * 2

    ; bx = 10 (decimal)
    mov bx, 10d
    
    ; ax = num
    mov ax, [bp + 4]
    
dec_step:
    mov dx, 0
    ; ax = ax / bx
    ; dx = ax % bx
    div bx
    
    ; cx = ax (div)
    mov cx, ax

    ; ax = dx (rem)
    mov ax, dx
    
    ; ax = digit to print
    add ax, '0'
    mov ah, num_CLR
    stosw
    
    ; ax = cx (div)
    mov ax, cx
    
    cmp ax, 0
    jne dec_step
    
    cld
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp
    
;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   printBin                      HHH
;HHH - print a number as binary                      HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > num  (the number to print)    HHH
;HHH                   x    (position x)             HHH
;HHH                   y    (position y)             HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          DI, ES                                 HHH
;HHH                                                 HHH
;HHH WARNING: reverse printing                       HHH
;HHH                                                 HHH
;HHH=================================================HHH

printBin proc
    push bp
    mov bp, sp
    
    ; num = [bp + 4]
    ;   x = [bp + 6]
    ;   y = [bp + 8]
    
    ;---------------------------------------------
    
    std
    
    ; es -> video memory
    mov ax, VIDEO_MEM
    mov es, ax
    
    ; di -> (x, y)
        mov ax, [bp + 8]    ;
        mov bx, CONS_WIDTH  ; ax = y * CONS_WIDTH
        mul bx              ;
        
        add ax, [bp + 6]    ; ax += x
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = (y * CONS_WIDTH + 2) * 2

    ; ax = num
    mov ax, [bp + 4]
    
bin_step:
    push ax
    
    ; ax % 2 <=> last bit
    and ax, 01h
    
    ; ax = digit to print
    add al, '0'
    mov ah, num_CLR
    stosw
    
    pop ax

    ; ax /= 2
    shr ax, 1
    
    cmp ax, 0
    jne bin_step
    
    cld
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp
    
;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   printHex                      HHH
;HHH - print a number as a hex number                HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > num  (the number to print)    HHH
;HHH                   x    (position x)             HHH
;HHH                   y    (position y)             HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          DI, ES                                 HHH
;HHH                                                 HHH
;HHH WARNING: reverse printing                       HHH
;HHH                                                 HHH
;HHH=================================================HHH

printHex proc
    push bp
    mov bp, sp
    
    ; num = [bp + 4]
    ;   x = [bp + 6]
    ;   y = [bp + 8]
    
    ;---------------------------------------------
    
    std
    
    ; es -> video memory
    mov ax, VIDEO_MEM
    mov es, ax
    
    ; di -> (x, y)
        mov ax, [bp + 8]    ;
        mov bx, CONS_WIDTH  ; ax = y * CONS_WIDTH
        mul bx              ;
        
        add ax, [bp + 6]    ; ax += x
        
        shl ax, 1           ; ax *= 2
    mov di, ax              ; res: di = (y * CONS_WIDTH + 2) * 2

    ; ax = num
    mov ax, [bp + 4]
    
hex_step:           
    push ax
    
    ; ax % 2 <=> last 4 bits (F = 1111)
    and ax, 0Fh
    
    cmp ax, 10d
    jb hex_isnumber
        add al, 'A'  - '0' - 10
hex_isnumber:

    ; ax = digit/char to print
    add al, '0'
    mov ah, num_CLR
    stosw
    
    pop ax
    
    ; ax /= 16
    shr ax, 4
    
    cmp ax, 0
    jne hex_step
    
    cld
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp

;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   getDec                        HHH
;HHH - interprete string as decimal number           HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > str (string position)         HHH
;HHH  OUTPUT: BX                                     HHH
;HHH DESTROY: AX, BX, CX, DX                         HHH
;HHH          SI, DI                                 HHH
;HHH                                                 HHH
;HHH=================================================HHH

getDec proc
    push bp
    mov bp, sp
    
    ; str = [bp + 4]
    
    ;---------------------------------------------
    
    cld
    
    ; si -> str
    mov si, [bp + 4]
    
    ; push position si - 1 (start of line)
    dec si
    push si
    inc si
    
    ; search for '$' - end of line
dec_getend:
    lodsb
    cmp al, '$'
    jne dec_getend
    
    sub si, 2
    
    std
    
    mov ax, 0   ; corrent digit
    mov bx, 0   ; total   number
    mov cx, 1   ; power
getDec_loop:
    ; ax = [si--]
    lodsb
    
    ; char => number
    sub ax, '0'
    
    ; ax *= 10^cl
    mul cl
    
    push ax
    
    mov ax, cx  ;
    shl ax, 1   ;
    shl cx, 3   ; cx *= 10
    add cx, ax  ;
    
    pop ax
    
    ; total += digit
    add bx, ax
    
    cmp si, [bp - 2]
    jne getDec_loop
    ; until si == start of line
    
    pop si
    cld
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp
    
;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   getBin                        HHH
;HHH - interprete string as binary number            HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > str (string position)         HHH
;HHH  OUTPUT: BX                                     HHH
;HHH DESTROY: AX, BX, CX                             HHH
;HHH          SI, DI                                 HHH                                                 ;HHH                                                 HHH
;HHH=================================================HHH

getBin proc
    push bp
    mov bp, sp
    
    ; str = [bp + 4]
    
    ;---------------------------------------------
    
    cld
    
    ; si -> str
    mov si, [bp + 4]
    
    ; push position si - 1 (start of line)
    dec si
    push si
    inc si
    
    ; search for '$' - end of line
bin_getend:
    lodsb
    cmp al, '$'
    jne bin_getend
    
    sub si, 2
    
    std
    
    mov ax, 0   ; current digit
    mov bx, 0   ; total   number
    mov cx, 0   ; power
getBin_loop:
    ; ax = [si--]
    mov ax, 0
    lodsb
    
    ; char => number
    sub ax, '0'
    
    ; ax *= 2^cl
    shl ax, cl
    
    ; cx *= 2
    inc cx
    
    ; total += digit
    add bx, ax
    
    cmp si, [bp - 2]
    jne getBin_loop
    ; until si == start of line
    
    pop si
    cld
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp

;HHH=================================================HHH
;HHH                                                 HHH
;HHH                   getHex                        HHH
;HHH - interprete string as hex number               HHH
;HHH                                                 HHH
;HHH   INPUT: stack: > str (string position)         HHH
;HHH  OUTPUT: BX                                     HHH
;HHH DESTROY: AX, BX, CX                             HHH
;HHH          SI, DI                                 HHH
;HHH                                                 HHH
;HHH=================================================HHH

getHex proc
    push bp
    mov bp, sp
    
    ; str = [bp + 4]
    
    ;---------------------------------------------
    
    cld
    
    ; si -> str
    mov si, [bp + 4]
    
    ; push position si - 1 (start of line)
    dec si
    push si
    inc si
    
    ; search for '$' - end of line
hex_getend:
    lodsb
    cmp al, '$'
    jne hex_getend
    
    sub si, 2
    
    std
    
    mov ax, 0   ; current digit
    mov bx, 0   ; total   number
    mov cx, 0   ; power
getHex_loop:
    ; ax = [si--]
    mov ah, 0
    lodsb
    
    cmp ax, 'a'
    jb getHex_less_small
        add ax, -'a' + 'A'
getHex_less_small:

    cmp ax, 'A'
    jb getHex_less_letter
        add ax, -'A' + 10 + '0'
getHex_less_letter:

    sub ax, '0'
    
    ; ax *= 2^cl
    shl ax, cl
    
    ; cx += 4 (0 -> 16 -> 256 -> ...)
    add cx, 4
    
    ; total += digit
    add bx, ax
    
    cmp si, [bp - 2]
    jne getHex_loop
    ; until si == start of line
    
    pop si
    cld
    
    ;---------------------------------------------
    
    pop bp
    ret
    endp

;HHH=================================================HHH
;HHH                                                 HHH
;HHH             (!!!) INLINE (!!!)                  HHH
;HHH                                                 HHH
;HHH                   print_msg                     HHH
;HHH - print a message                               HHH
;HHH                                                 HHH
;HHH   INPUT: AH - color of text                     HHH
;HHH          SI - message to print                  HHH
;HHH          DI - position to print                 HHH
;HHH  OUTPUT: --                                     HHH
;HHH DESTROY: AX                                     HHH
;HHH          SI, DI                                 HHH
;HHH                                                 HHH
;HHH=================================================HHH

print_msg:
    lodsb
    cmp al, '$'
    je endmsg
        stosw
        jmp print_msg
endmsg:
    ret

;=================================================
    
.data
ax_ten     db 'So ax is 10$'
ax_not_ten db 'Ax is not 10$'
msg        db 'Some Yota ad.*$'
msg2       db '* - some useless star.$'

end
