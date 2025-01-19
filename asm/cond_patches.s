; This file is reserved for conditional (0x2B) scene patches, still using the same area of code
; as the custom Tickflow commands.

FanClub_branch      equ 0x003453f4
FanClub_success     equ 0x0034540c
FanClub_fail        equ 0x003453f8

getSpecialVer       equ 0x00257a78

@moreNewCode:

; Fan Club patch
; Hoping This Works TM

; instead of branching to the clap function if not jumping, add an extra check
.org FanClub_branch
    b FanClub_check

.org @moreNewCode

FanClub_check:
    ; original instruction
    beq FanClub_success
    push {r0, r1, r2, r3, r12, lr}

    ; check 0x2B mode for Fan Club (0x15)
    mov r0, #0x15
    bl getSpecialVer
    cmp r0, #0xf

    pop {r0, r1, r2, r3, r12, lr}

    ; if mode is appropiate, do clap input anyway
    beq FanClub_success

    ; otherwise, work as intended
    b FanClub_fail