; FS redirection patch for Rhythm Heaven Megamix

.arm.little
.open "original.bin", "code.bin", 0x100000

; custom commands
.include "asm/custom_cmds.s"

openFile            equ 0x279E60 ; svc 0x32 (0x08030204)
getSize             equ 0x2BC628 ; svc 0x32 (0x08040000)
readFile            equ 0x2BC544 ; svc 0x32 (0x080200C2)
closeFile           equ 0x2BC59C ; svc 0x32 (0x08080000)
svcControlMemory    equ 0x27F6CC ; svc 1

; cfguHandleOffset = 0x54DCB4
; cfgGetRegion = 0x1238C0

userFsTryOpen       equ 0x2859B4
mountSD             equ 0x2BC660
throwFatalError     equ 0x273CA8

mountHook           equ 0x28B41C

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
path:   .asciiz "/rhmm/C00.bin"
pathend:
sdRoot: .asciiz "_:"
sdPath: .asciiz "_:/rhmm"

; overwrite all the offsets! -- changed from 0x52B498
.org 0x109008
    .dw 0x0C000000
.org 0x22D57C
    .dw 0x0C000000
.org 0x22D67C
    .dw 0x0C000000
.org 0x22D698
    .dw 0x0C000000
.org 0x22D6B4
    .dw 0x0C000000
.org 0x22D6D0
    .dw 0x0C000000
.org 0x240458
    .dw 0x0C000000
.org 0x24CB28
    .dw 0x0C000000
.org 0x2553CC
    .dw 0x0C000000
.org 0x255578
    .dw 0x0C000000
.org 0x258618
    .dw 0x0C000000
.org 0x258E0C
    .dw 0x0C000000
.org 0x32D434
    .dw 0x0C000000
.org 0x32D450
    .dw 0x0C000000
.org 0x32D470
    .dw 0x0C000000
.org 0x32D4C8
    .dw 0x0C000000
.org 0x32D548
    .dw 0x0C000000
.org 0x32D5B0
    .dw 0x0C000000
.org 0x32D5E8
	.dw 0x0C000000

; overwrite more offsets! Changed from 0x53EF54
.org 0x101C10
    .dw 0x0C001588
.org 0x12B3B0
    .dw 0x0C001588
    
; yet more offsets; changed from 0x52E488
.org 0x22AE40
    .dw 0x0C003358
.org 0x240FB0
    .dw 0x0C003358
.org 0x2552D8
    .dw 0x0C003358
.org 0x32D5FC
    .dw 0x0C003358
.org 0x32D614
    .dw 0x0C003358
.org 0x32D62C
    .dw 0x0C003358
.org 0x32D644
    .dw 0x0C003358
.org 0x32D65C
    .dw 0x0C003358
.org 0x32D6B8
    .dw 0x0C003358
.org 0x32D770
    .dw 0x0C003358

; Prologue jingle patch

gateJingleFunc  equ 0x32D678
newCode         equ 0x399F00
prologueJingles equ 0x52C9B8

.org gateJingleFunc
    mov r2, r0
    b newCode

.org newCode
    adr r1, pr_pj
    ldr r1, [r1]
    mov r0, #0
    b pr_label1
pr_pj: .dw prologueJingles
pr_label1:
    add r3, r1, r0, lsl #3
    ldr r12, [r3]
    cmp r12, r2
    bne pr_label3
    ldr r0, [r3, #4]
    bx lr
pr_label3:
    add r0, r0, #1
    cmp r0, #0x2a
    blt pr_label1
    adr r0, pr_nf
    bx lr
pr_nf: .asciiz "NotFoundAac"
pr_end:

.close