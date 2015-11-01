;


.MODEL SMALL
 
_DATA        segment    public

;global variables
vk_002        dw    ?
vf_001        dw    ?
 
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
	vt_005        equ    dword  ptr	[bp-0008h]
	vf_004        equ    word  ptr	[bp-0006h]
; arguments in go
ab_009        equ    word  ptr	[bp+0008h]
aa_010        equ    word  ptr	[bp+0006h]
;routine code
rtn001        proc
        assume    cs:_TEXT,ds:_DATA
        mov    ax,_DATA
        mov    ds,ax
        push    bp
        mov    bp,sp
        sub    sp, 4
        sub    sp,0006h
        mov    ax,word ptr aa_010
        push    ax
        mov    ax,00h
        pop    dx
        cmp    dx,ax
        mov    ax,1
        jg    j_001
        sub    ax,ax
j_001:
        cmp    ax,1
        je    if_t0001h
        jmp    if_f0001h
if_t0001h:
        mov    ax,word ptr aa_010
        push    ax
        mov    bx,word ptr ab_009
        mov    ax,word ptr [bx]
        push    ax
        mov    ax,word ptr aa_010
        push    ax
        mov    ax,01h
        pop    dx
        sub    dx,ax
        mov    ax,dx
        push    ax
        push    static_link
        call rtn001
        pop    dx
        imul    dx
        mov    word ptr retval_addr,ax
        jmp    if_x0001h
if_f0001h:
        mov    ax,01h
        mov    word ptr retval_addr,ax
if_x0001h:
        mov    bx,word ptr ab_009
        mov    ax,word ptr [bx]
        push    ax
        pop    dx
        add    ax,dx
        push    ax
        mov    ax,word ptr ab_009
        pop    bx
        pop    ax
        mov    word  ptr [bx],ax
        mov    ax,word ptr vk_002
        mov    bx,bp
        mov    bp,static_link
        mov    ax,word ptr vk_002
        mov    bp,bx
        push    ax
        pop    dx
        add    ax,dx
        mov    word  ptr vk_002, ax

        mov    ax, word ptr retval_addr
        mov    sp,bp
        pop    bp
        ret    0006h

rtn001        endp


; --- main routine ----
_main        proc    far
        assume    cs:_TEXT,ds:_DATA
        push    ds
        sub    ax,ax
        push    ax
        mov    ax,_DATA
        mov    ds,ax
        mov    ax,00h
        mov    word  ptr vk_002, ax
        mov    ax,word ptr vk_002
        push    ax
        mov    ax,05h
        push    ax
        push    bp
        call rtn001
        mov    word  ptr vf_001, ax
        mov    ax,word ptr vf_001
        push    ax
        push    bp
        call    _write_int
        push     dx
        mov      dl, 0dh
        int 	  21h
        mov	  dl, 0ah
        int	  21h
        pop      dx
        mov    ax,word ptr vk_002
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

