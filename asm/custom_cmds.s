; Jumptable for custom commands

common_cmd_default  equ 0x0025c3c0
common_cmd_return   equ 0x002613cc

cmd_amount equ 1

.org common_cmd_default
    b jt_switchcase

.org pr_end

jt_switchcase:
    sub r1, #0x200
    cmp r1, #0
    blt common_cmd_return
    cmp r1, cmd_amount
    ldrcc pc, [pc, r1, lsl #2] ; since jt_table is right there
    b common_cmd_return
jt_table:
    .word input_command
jt_end:

; Input checker command

cmd_1f_offset       equ 0x0025c440

gSaveData           equ 0x0054d350
gInputManager       equ 0x0054eed0

.org cmd_1f_offset
    .dw input_command

.org jt_end

; r2 - special arg / arg0
; r3 - cmd args
; r6 - game state

input_command:
    cmp r2, #2
    bhi in_null
    bcc in_getinput
    
    ; 0x200<2>: get simple tap vs buttons mode
    push {r0, r1, r3}

    ; loads from save
    ldr r0, =gSaveData
    ldr r0, [r0]

    ; 0x2dc8 (gSaveData->fileData + fileData.isSimpleTap)
    mov r1, #0xb7
    lsl r1, r1, #6
    add r1, r1, #8

    ; 0x1648 (sizeof(individual save))
    mov r2, #0x59
    lsl r2, r2, #6
    add r2, r2, #8
    
    ; 0x7560 (gSaveData->currentFile)
    mov r3, #0x75
    lsl r3, r3, #8
    add r3, #0x60

    ; final offset: gSaveData->fileData[gSaveData->currentFile].isSimpleTap
    ldr r3, [r0, r3]
    mul r2, r2, r3
    add r2, r2, r1
    ldrb r2, [r0, r2]

    pop {r0, r1, r3}
in_getinput:
    ldr r0, =gInputManager
    ldr r0, [r0]
    cmp r2, #1
    bhi in_touch

    ; 0x200<0>: check for button input at specified bit
    ; don't shift by 32 bits or more, that'll always be 0
    ldr r1, [r3] ; args[0]
    cmp r1, #0x20
    bcs in_null

    ; load input data (u32 bitflags) @ gInputManager->unk4->unk4
    ldr r0, [r0, #4]
    ldr r0, [r0, #4]

    ; set condvar to bit number args[0]
    lsr r0, r0, r1
    and r0, r0, #1
    str r0, [r6, #0x20]
    b common_cmd_return
in_touch:
    ; 0x200<1>: check for touchscreen input @ gInputManager->unk8->unkC
    ldr r0, [r0, #8]
    ldrb r0, [r0, #0xc]
    str r0, [r6, #0x20]
    b common_cmd_return
in_null:
    ; set condvar to 0
    mov r0, #0
    str r0, [r6, #0x20]
    b common_cmd_return

.pool