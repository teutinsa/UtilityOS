%macro FUNC 1
%1:
	push bp,
	mov bp, sp
%endmacro

%macro END 1
	pop bp
	ret (%1*2)
%endmacro

%macro ldarg 2
	mov %1, [bp+(4+(2*%2))]
%endmacro

%macro INVOKE 1-*
	%rep %0-1
		%rotate -1
		push %1
	%endrep
	%rotate -1
	call %1
%endmacro

[bits 16]
[org 0x7C00]

SECTION2 equ 0x7E00

_start:
	mov [BootDisk], dl

	mov ax, 0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov sp, 0x7BFF
	mov bp, sp
	
	mov ah, 0x02
	mov al, 1
	mov ch, 0
	mov cl, 1
	mov dh, 0
	mov dl, [BootDisk]
	mov bx, SECTION2
	int 0x13

	.error:
	INVOKE Print, ErrorString
	jmp $

FUNC Print
	ldarg bx, 0
	mov ah, 0x0E
	.loop:
	mov al, [bx]
	cmp al, 0
	je .end
	inc bx
	int 0x10
	jmp .loop
	.end:
END 1

BootDisk: db 0
ErrorString: db "Critical Error!!!", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55

[bits 16]
FUNC CheckCPUID
	
END 0

times 1024-($-$$) db 0