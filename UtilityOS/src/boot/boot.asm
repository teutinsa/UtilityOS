[bits 16]
[org 0x7C00]

SECTION2 equ 0x7E00
MMAP equ 0x8000

_start:
	;store boot disk number
	mov [BootDisk], dl

	;setup data segment registers
	mov ax, 0
	mov es, ax
	mov ds, ax
	mov ss, ax

	;setup stack
	mov bp, 0x7BFE
	mov sp, bp

	;load extra segent
	cld
	mov ah, 0x02
	mov al, 1
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, [BootDisk]
	mov bx, SECTION2
	int 0x13
	jc .error
	
	;check if CPUID is supported, if not error
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

	push WORD MMAP
	call MakeMemoryMap
	jc .error

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

MakeMemoryMap:
	push bp
	mov bp, sp
	sub sp, 4			;alloc 4 bytes on stack

	mov di, [bp+4]		;move first argument to DI
	add di, 4

	mov ebx, 0
	mov edx, 0x0534D4150
	mov eax, 0xE820
	mov [es:di+20], DWORD 1
	mov ecx, 24
	int 0x15
	jc .failed
	mov edx, 0x0534D4150
	cmp eax, edx
	jne .failed
	test ebx, ebx
	je .failed
	jmp .start
	
	.loop:
	mov eax, 0xE820
	mov [es:di+20], DWORD 1
	mov ecx, 24
	int 0x15
	jc .done
	mov edx, 0x0534D4150

	.start:
	jcxz .skip
	cmp cl, 20
	jbe .notext
	test BYTE [es:di+20], 1
	je .skip

	.notext:
	mov ecx, [es:di+8]
	or ecx, [es:di+12]
	jz .skip
	inc DWORD [bp-4]
	add di, 24

	.skip:
	test ebx, ebx
	jne .loop

	.done:
	mov eax, [bp-4]
	mov [bp+4], eax
	clc
	jmp .end

	.failed:
	stc

	.end:
	mov sp, bp
	pop bp
	ret 2

times 1024-($-$$) db 0