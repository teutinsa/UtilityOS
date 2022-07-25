[bits 16]
[org 0x7C00]

_start:
	
	jmp $

times 510-($-$$) db 0
dw 0xAA55