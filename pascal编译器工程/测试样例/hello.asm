;


.MODEL SMALL
 
_DATA        segment    public

;global variables
cz_001        db    'inta is :'
        db    '$'
vi_003        dw    ?
vi_002        dw    ?
vi_001        dw    ?
 
;alloc stack space
         db    0800h dup(?)

_DATA        ends

;---program helloworld ---

_TEXT        segment    public

        include    x86rtl.inc

static_link    equ    word ptr [bp+04h]
retval_addr    equ    word ptr [bp-04h]
retval_addr_hi    equ    word ptr [bp-02h]


; --- main routine ----
_main        proc    far
        assume    cs:_TEXT,ds:_DATA
        push    ds
        sub    ax,ax
        push    ax
        mov    ax,_DATA
        mov    ds,ax
        mov    ax,014h
        mov    word  ptr vi_003, ax
        mov    ax,0ah
        push    ax
        mov    ax,014h
        pop    dx
        add    ax,dx
        mov    word  ptr vi_002, ax
        mov    ax,word ptr vi_002
        push    ax
        mov    ax,03h
        pop    dx
        imul    dx
        push    ax
        mov    ax,02h
        push    ax
        mov    ax,word ptr vi_003
        push    ax
        mov    ax,word ptr vi_002
        pop    dx
        add    ax,dx
        pop    dx
        imul    dx
        pop    dx
        add    ax,dx
        mov    word  ptr vi_001, ax
        lea    ax,cz_001
        push    ax
        push    bp
        call    _write_string
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

