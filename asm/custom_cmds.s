; Jumptable for custom commands

common_cmd_default  equ 0x0025c3c0
common_cmd_return   equ 0x002613cc

; Supported commands: 0x200, 0x201, 0x202, 0x205
; Saltwater-only commands: 0x203, 0x204

cmd_amount equ 6

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
    .word version_command
    .word language_command
    .word common_cmd_return
    .word endless_command
jt_end:

; Registers' values

; r2 - special arg / arg0
; r3 / r5 - cmd args
; r6 - game state

; 0x201 - Quick version check
version_command:
    cmp r2, #0
    bne common_cmd_return

    mov r0, MAJOR_VERSION * 0x100
    add r0, r0, MINOR_VERSION
    str r0, [r6, #0x20]
    b common_cmd_return

; 0x200 - Input checker command
gSaveData           equ 0x0054d350
gInputManager       equ 0x0054eed0

input_command:
    cmp r2, #2
    bhi in_null
    bcc in_getinput
    
    ; 0x200<2>: get simple tap vs buttons mode
    push {r3}

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

    pop {r3}
in_getinput:
    ldr r0, =gInputManager
    ldr r0, [r0]
    cmp r2, #0
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

; 0x202 - Language command

language_command:
    cmp r2, #0
    bne common_cmd_return

    ldr r0, =gSaveData
    ldr r0, [r0]

    ; 0x2d03 (gSaveData->fileData + fileData.isJapanese)
    mov r1, #0x2d
    lsl r1, r1, #8
    add r1, r1, #3

    ; 0x1648 (sizeof(individual save))
    mov r2, #0x59
    lsl r2, r2, #6
    add r2, r2, #8
    
    ; 0x7560 (gSaveData->currentFile)
    mov r3, #0x75
    lsl r3, r3, #8
    add r3, #0x60

    ; final offset: gSaveData->fileData[gSaveData->currentFile].isJapanese
    ldr r3, [r0, r3]
    mul r2, r2, r3
    add r2, r2, r1
    ldrb r2, [r0, r2]
    eor r2, r2, #1
    str r2, [r6, #0x20]
    b common_cmd_return

.pool

; 0x205 - EndlessPatch replacement
D_0054ef10      equ 0x0054ef10 ; no clue what this is
gSaveManager    equ 0x0054ef28

isGateGameValid equ 0x00255550
getGateScore    equ 0x00261a6c
setGateScore    equ 0x002366c0
saveGame        equ 0x0028bf14 

endless_command:
    cmp r2, #0
    bne common_cmd_return

    ldr r5, =gSaveData
    ldr r5, [r5]

    ; get current slot
    ldr r0, =D_0054ef10
    ldr r0, [r0]
    ldrb r4, [r0, 0x4c] ; current gate slot - not updated if this is a non-gate game

    ; must only be run on an endless game, not a gate game
    mov r1, 0b11
    and r1, r4, r1
    cmp r1, #3
    bne common_cmd_return
    
    ; gate game has to be valid
    mov r0, r4
    bl isGateGameValid
    cmp r0, #0
    beq common_cmd_return

    ; get saved score
    mov r0, r5
    mov r1, r4
    mvn r2, #0      ; r2 = -1
    bl getGateScore

    ; if the saved score is bigger or equal to the current score, don't save
    ldr r2, [r6, #0x20]
    cmp r0, r2
    bge common_cmd_return

    ; save condvar to score
    mov r0, r5
    mov r1, r4
    mvn r3, #0      ; r3 = -1
    bl setGateScore

    ; save the game
    ldr r5, =gSaveManager
    ldr r5, [r5]
    bl saveGame

    b common_cmd_return

.pool
