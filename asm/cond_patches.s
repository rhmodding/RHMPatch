; This file is reserved for conditional (0x2B) scene patches, still using the same area of code
; as the custom Tickflow commands.

FanClub_branch      equ 0x003453f4
FanClub_success     equ 0x0034540c
FanClub_isJumping   equ 0x003454fc

getSpecialVer       equ 0x00257a78

@moreNewCode:

; Fan Club patch - I don't remember what any of this did
; why is this patch always active????
.org FanClub_branch
    beq FanClub_success
    ;b FanClub_check

.org @moreNewCode

FanClub_check:
    push {lr}

    ; check 0x2B mode for Fan Club (0x15)
    mov r0, #0x15
    bl getSpecialVer
    cmp r0, #0xf

    pop {lr}

    beq FanClub_success

    ldr r0, [r6]  ; first instruction from the original check
    b FanClub_isJumping