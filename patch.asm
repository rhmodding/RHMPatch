; FS redirection patch for Rhythm Heaven Megamix

.arm.little
;.open "rhmm_Edited.3ds", "rhmm_Patched.3ds", 0x100000 - 0x6E00
.open "original.bin", "code.bin", 0x100000

openFile equ 0x279E60 ; svc 0x32 (0x08030204)
getSize equ 0x2BC628 ; svc 0x32 (0x08040000)
readFile equ 0x2BC544 ; svc 0x32 (0x080200C2)
closeFile equ 0x2BC59C ; svc 0x32 (0x08080000)
svcControlMemory equ 0x27F6CC ; svc 1

; cfguHandleOffset = 0x54DCB4
; cfgGetRegion = 0x1238C0

userFsTryOpen equ 0x2859B4
mountSD equ 0x2BC660
throwFatalError equ 0x273CA8

mountHook equ 0x28B41C

; patch region
.org 0x119560
	mov r0, 1
	bx lr

.org 0x100000 ; hook from the start!
	bl allocateMemory_payload

.org mountHook
	b mountsd_and_C00_payload

.org userFsTryOpen
    b userFsTryOpen_payload

.org 0x1238C0 ; where cfgGetRegion originally was
allocateMemory_payload:
	; here we allocate something of a suitable length
	push r0-r2, lr
	add r0, sp, 8     ; pointer to output address
	mov r1, 0xC000000 ; address
	mov r2, 0         ; ?
	mov r3, 0x200000  ; size to allocate = 2 MB
	mov r4, 3
	str r4, [sp, 0]   ; allocate
	str r4, [sp, 4]   ; read | write
	bl svcControlMemory
	pop r0-r2, lr
	b 0x100024

.org throwFatalError	
mountsd_and_C00_payload:
	bl 0x118D1C ; original opcode

	ldr r0, =sdRoot
	bl mountSD
	
	sub sp, 0x24
	
	; open file for reading
	ldr r0, =0x54DD18 ; r0 = fsSession()
	add r1, sp, 0x20  ; r1 = pointer to output FileHandle
	mov r2, 0         ; r2 = transaction = 0
	mov r3, 9         ; r3 = Archive ID = SDMC
	mov r4, 1
	str r4, [sp, 0x00] ; Archive PathType = EMPTY
	str r2, [sp, 0x04] ; Archive DataPointer
	str r2, [sp, 0x08] ; Archive PathSize
	mov r5, 3
	str r5, [sp, 0x0C] ; File PathType = ASCII
	ldr r5, =path
	str r5, [sp, 0x10] ; File DataPointer = path
	mov r5, pathend-path
	str r5, [sp, 0x14] ; File PathSize = 3
	str r4, [sp, 0x18] ; File OpenFlags = READ
	str r2, [sp, 0x1C] ; Attributes = 0
	bl openFile
	
	; get filesize
	add r0, sp, 0x20 ; r0 = pointer to FileHandle
	add r1, sp, 0x10 ; r1 = pointer to Filesize
	bl getSize
	
	; read contents into buffer
	add r0, sp, 0x20 ; r0 = pointer to FileHandle
	add r1, sp, 8    ; r1 = pointer to bytesRead
	mov r2, 0        ; r2 = offset (lower word)
	mov r3, 0        ; r3 = offset (higher word)
	mov r4, 0xC000000
	str r4, [sp]     ; buffer
	ldr r4, [sp, 0x10]
	str r4, [sp, 4]  ; size
	bl readFile

	; close the file
	add r0, sp, 0x20 ; r0 = pointer to FileHandle
	bl closeFile
		
	add sp, 0x24
	b mountHook + 4

userFsTryOpen_payload:
	push r4-r8,lr
	ldrh r3, [r1]
	cmp r3, '_'
	beq userFsTryOpen + 4	
	sub sp, 0x100
	push r0-r2

	; string manipulation
	add r0, sp, 0x10
	ldr r1, =sdPath
	strcpy1:
		ldrb r2, [r1], 1
		cmp r2, 0
		strneh r2, [r0], 2
		bne strcpy1
	ldr r1, [sp, 4]
	strchr:
		ldrh r2, [r1], 2
		cmp r2, ':'
		bne strchr
	strcpy2:
		ldrh r2, [r1], 2
		strh r2, [r0], 2
		cmp r2, 0
		bne strcpy2
		
	ldr r0, [sp]
	add r1, sp, 0x10
	mov r2, 1
	bl userFsTryOpen
	movs r1, r0, lsr 31
	popne r0-r2
	addeq sp, 0xC
	add sp, 0x100
	popeq r4-r8,pc
	b userFsTryOpen + 4

.pool
; an extremely tight fit! cannot even fit one more instruction!

.org 0x198C9C
	mov r2, 0xE
	
.org 0x16302C
	mov r2, 0xE
	
.org 0x1F7F84
	mov r2, 0xE

.org 0x52B498 ; place all the path information in the old pointer table address
path: .db "/rhmm/C00.bin", 0
pathend:
sdRoot: .db "_:", 0
sdPath: .db "_:/rhmm",0

; overwrite all the offsets! -- changed from 0x52B498
.org 0x109008
	.db 0,0,0,0xC
.org 0x22D57C
	.db 0,0,0,0xC
.org 0x22D67C
	.db 0,0,0,0xC
.org 0x22D698
	.db 0,0,0,0xC
.org 0x22D6B4
	.db 0,0,0,0xC
.org 0x22D6D0
	.db 0,0,0,0xC
.org 0x240458
	.db 0,0,0,0xC
.org 0x24CB28
	.db 0,0,0,0xC
.org 0x2553CC
	.db 0,0,0,0xC
.org 0x255578
	.db 0,0,0,0xC
.org 0x258618
	.db 0,0,0,0xC
.org 0x258E0C
	.db 0,0,0,0xC
.org 0x32D434
	.db 0,0,0,0xC
.org 0x32D450
	.db 0,0,0,0xC
.org 0x32D470
	.db 0,0,0,0xC
.org 0x32D4C8
	.db 0,0,0,0xC
.org 0x32D548
	.db 0,0,0,0xC
.org 0x32D5B0
	.db 0,0,0,0xC
.org 0x32D5E8
	.db 0,0,0,0xC
	
; overwrite more offsets! Changed from 0x53EF54
.org 0x101C10
	.db 0x88,0x15,0,0xC
.org 0x12B3B0
	.db 0x88,0x15,0,0xC
	
; yet more offsets; changed from 0x52E488
.org 0x22AE40
	.db 0x58,0x33,0,0xC
.org 0x240FB0
	.db 0x58,0x33,0,0xC
.org 0x2552D8
	.db 0x58,0x33,0,0xC
.org 0x32D5FC
	.db 0x58,0x33,0,0xC
.org 0x32D614
	.db 0x58,0x33,0,0xC
.org 0x32D62C
	.db 0x58,0x33,0,0xC
.org 0x32D644
	.db 0x58,0x33,0,0xC
.org 0x32D65C
	.db 0x58,0x33,0,0xC
.org 0x32D6B8
	.db 0x58,0x33,0,0xC
.org 0x32D770
	.db 0x58,0x33,0,0xC

.close