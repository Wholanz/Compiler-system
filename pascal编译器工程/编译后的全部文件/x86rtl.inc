;header of asm

;_write_int		PROTO PASCAL intvalue:WORD
;_writeln_int	PROTO PASCAL intvalue:WORD
;_write_string	PROTO PASCAL stringptr:WORD
;_writeln_string	PROTO PASCAL stringptr:WORD
;_read_char		PROTO PASCAL charptr:WORD
;_read_string	PROTO PASCAL stringptr:WORD
;_read_int		PROTO PASCAL intptr:WORD
;_abs_int		PROTO PASCAL intvalue:WORD
;_sqr_int		PROTO PASCAL intvalue:WORD
;_odd_int		PROTO PASCAL intvalue:WORD
;_sqrt_int		PROTO PASCAL intvalue:WORD

EXTERNDEF _write_int:NEAR
EXTERNDEF _writeln_int:NEAR
EXTERNDEF _write_string:NEAR
EXTERNDEF _writeln_string:NEAR
EXTERNDEF _read_char:NEAR
EXTERNDEF _read_string:NEAR
EXTERNDEF _read_int:NEAR
EXTERNDEF _abs_int:NEAR
EXTERNDEF _sqr_int:NEAR
EXTERNDEF _odd_int:NEAR
EXTERNDEF _sqrt_int:NEAR
