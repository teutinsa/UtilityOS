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
	mov bp, 0x7BFF
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
	push WORD DiskErrorString
	jc .error
	add sp, 2
	
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
	push WORD CpuErrorString
	je .error
	add sp, 2

	call PrintCPUID

	push WORD MMAP
	call MakeMemoryMap
	push WORD MapErrorString
	jc .error
	add sp, 2

	cli
	lgdt [GdtDesc]
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp CODE_SEG:protected_mode

	.error:
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

Gdt:
	.null:
		dd 0
		dd 0
	.code:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0b10011010	
		db 0b11001111	
		db 0
	.data:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0b10010010
		db 0b11001111
		db 0
	.end:

GdtDesc:
	dw Gdt.end - Gdt - 1
	dd Gdt

CODE_SEG equ Gdt.code - Gdt
DATA_SEG equ Gdt.data - Gdt

BootDisk: resb 1
DiskErrorString: db "Disk read error!", 13, 10, 0
CpuErrorString: db "CPUID not supported error!", 13, 10, 0

[bits 32]
protected_mode:
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov ebp, 0x90000
	mov esp, ebp

	mov ah, 0x02
	mov al, 'P'
	mov WORD [0xB8000], ax

	jmp $

times 510-($-$$) db 0
dw 0xAA55

[bits 16]
MakeMemoryMap:
	push bp
	mov bp, sp
	sub sp, 4	;alloc 4 bytes on stack

	mov di, [bp+4]	;move first argument to DI
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

PrintCPUID:
	push bp
	mov bp, sp
	sub sp, 16	;alloc 16 bytes on stack

	;get cpu vendor string
	mov eax, 0
	cpuid

	;move cpu string to stack
	mov [bp-16], ebx
	mov [bp-12], edx
	mov [bp-8], ecx
	mov [bp-4], DWORD 0x0A0D

	push WORD CpuString
	call Print

	mov ax, bp
	sub ax, 16
	push WORD ax
	call Print

	mov sp, bp
	pop bp
	ret

MapErrorString: db "Memory map error!", 13, 10, 0
CpuString: db "CPU: ", 0

times 1024-($-$$) db 0