;


.MODEL SMALL
 
_DATA        segment    public

;global variables
vi_001        dw    ?
 
;alloc stack space
         db    0800h dup(?)

_DATA        ends

;---program hello ---

_TEXT        segment    public

        include    x86rtl.inc

static_link    equ    word ptr [bp+04h]
retval_addr    equ    word ptr [bp-04h]
retval_addr_hi    equ    word ptr [bp-02h]


; routine : go 
;local variables in go
; arguments in go
aa_009        equ    word  ptr	[bp+0006h]
;routine code
rtn001        proc
        assume    cs:_TEXT,ds:_DATA
        mov    ax,_DATA
        mov    ds,ax
        push    bp
        mov    bp,sp
        sub    sp, 4
        sub    sp,0000h
        mov    ax,word ptr aa_009
        push    ax
        mov    ax,01h
        pop    dx
        cmp    dx,ax
        mov    ax,1
        je    j_001
        sub    ax,ax
j_001:
        cmp    ax,1
        je    if_t0001h
        jmp    if_f0001h
if_t0001h:
        mov    ax,01h
        mov    word ptr retval_addr,ax
        jmp    if_x0001h
if_f0001h:
        mov    ax,word ptr aa_009
        push    ax
        mov    ax,02h
        pop    dx
        cmp    dx,ax
        mov    ax,1
        je    j_002
        sub    ax,ax
j_002:
        cmp    ax,1
        je    if_t0002h
        jmp    if_f0002h
if_t0002h:
        mov    ax,01h
        mov    word ptr retval_addr,ax
        jmp    if_x0002h
if_f0002h:
        mov    ax,word ptr aa_009
        push    ax
        mov    ax,01h
        pop    dx
        sub    dx,ax
        mov    ax,dx
        push    ax
        push    static_link
        call rtn001
        push    ax
        mov    ax,word ptr aa_009
        push    ax
        mov    ax,02h
        pop    dx
        sub    dx,ax
        mov    ax,dx
        push    ax
        push    static_link
        call rtn001
        pop    dx
        add    ax,dx
        mov    word ptr retval_addr,ax
if_x0002h:
if_x0001h:

        mov    ax, word ptr retval_addr
        mov    sp,bp
        pop    bp
        ret    0004h

rtn001        endp


; --- main routine ----
_main        proc    far
        assume    cs:_TEXT,ds:_DATA
        push    ds
        sub    ax,ax
        push    ax
        mov    ax,_DATA
        mov    ds,ax
        mov    ax,0ah
        push    ax
        push    bp
        call rtn001
        mov    word  ptr vi_001, ax
        mov    ax,word ptr vi_001
        push    ax
        push    bp
        call    _write_int
        push     dx
        mov      dl, 0dh
        int 	  21h
        mov	  dl, 0ah
        int	  21h
        pop      dx
        ret
_main        endp

_TEXT        ends
        end _main

