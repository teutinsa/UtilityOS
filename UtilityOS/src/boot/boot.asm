[bits 16]
[org 0x7C00]

SECTION2 equ 0x7E00

_start:
	;store boot disk number
	mov [BootDisk], dl

	;setup data segment registers
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	;setup stack
	mov sp, 0x7BFF
	mov bp, sp

	;load extra segent
	mov ah, 0x02
	mov al, 1
	mov ch, 0
	mov cl, 1
	mov dh, 0
	mov dl, [BootDisk]
	mov bx, SECTION2
	int 0x13
	jc .error
	
	;check if CPUID is supported
	pushfd
	pushfd
	xor DWORD [esp], 0x00200000
	popfd
	pushfd
	pop eax
	xor eax, [esp]
	popfd
	and eax, 0x00200000
	je .error

	jmp $

	.error:
	push WORD ErrorString
	call Print
	jmp $
	
Print:
	push bp
	mov bp, sp
	mov bx, [bp+4]
	mov ah, 0x0E
	.loop:
	mov al, [bx]
	cmp al, 0
	je .end
	inc bx
	int 0x10
	jmp .loop
	.end:
	mov sp, bp
	pop bp
	ret 2

BootDisk: resb 1
ErrorString: db "Bootloader error!", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55


times 1024-($-$$) db 0