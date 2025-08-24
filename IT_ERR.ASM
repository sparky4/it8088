;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Critical Error handler.                                                     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

                        Jumps
                        .8086

include switch.inc

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Externals                                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Globals                                                                     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

                Global  Error_InitHandler:Far
                Global  Error_UnInitHandler:Far

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

Segment                 Error BYTE Public 'Code' USE16
                        Assume CS:Error

CREATENEWLOGFILE        EQU     0
include debug.inc

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Variables                                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

OldHandlerOffset        DW      ?
OldHandlerSegment       DW      ?

ErrorMsgs               Label   Word
                        DW      Offset Error0
                        DW      Offset Error1
                        DW      Offset Error2
                        DW      Offset Error3
                        DW      Offset Error4
                        DW      Offset Error5
                        DW      Offset Error6
                        DW      Offset Error7
                        DW      Offset Error8
                        DW      Offset Error9
                        DW      Offset ErrorA
                        DW      Offset ErrorB
                        DW      Offset UnknownError
                        DW      Offset UnknownError
                        DW      Offset UnknownError
                        DW      Offset ErrorF

Error0          DB      "Write protect error", 0
Error1          DB      "Unknown unit error", 0
Error2          DB      "Drive not ready error", 0
Error3          DB      "Unknown command error", 0
Error4          DB      "Data integrity error", 0
Error5          DB      "Bad request structure length error", 0
Error6          DB      "Seek error", 0
Error7          DB      "Unknown media type error", 0
Error8          DB      "Sector not found error", 0
Error9          DB      "Printer error", 0
ErrorA          DB      "Read fault error", 0
ErrorB          DB      "General failure error", 0
ErrorF          DB      "Invalid disk change error", 0
UnknownError    DB      "Unknown critical error", 0

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Functions                                                                   ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Proc            ErrorHandler Far

;;                PushA
; The PUSHA equivalent for the 8086 processor
push ax
push cx
push dx
push bx
push sp
push bp
push si
push di

                Push    DS
                Push    ES

                Push    CS
                Pop     DS
                        Assume DS:Error

                Mov     BX, DI
                And     BX, 0FFh
                Cmp     BX, 0Fh
                JBE     ErrorHandler1

                Mov     SI, Offset UnknownError
                Jmp     ErrorHandler2

ErrorHandler1:
                Add     BX, BX
                Mov     SI, [ErrorMsgs+BX]

ErrorHandler2:
                Mov     AH, 20h
                Mov     DI, 0B800h
                Mov     ES, DI
                Mov     DI, (2+49*80)*2

ErrorHandler3:
                LodsB
                And     AL, AL
                JZ      ErrorHandler4
                StosW

                Jmp     ErrorHandler3

ErrorHandler4:
                Pop     ES
                Pop     DS
;;                PopA
; Equivalent of POPA for 8086
POP DI
POP SI
POP BP
ADD SP, 2 ; Discard the pushed SP value by incrementing the stack pointer
POP BX
POP DX
POP CX
POP AX


                Xor     AX, AX

                IRet

EndP            ErrorHandler
                Assume DS:Nothing

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Proc            Error_InitHandler Far

                Push    ES

                Trace   " - Installing error handler"

                Xor     AX, AX
                Mov     ES, AX

                Mov     AX, CS
;;                ShL     EAX, 16
    MOV DX, AX   ; Move the lower 16 bits (AX) to the upper 16 bits (DX).
    XOR AX, AX   ; Zero out the lower 16 bits (AX).
                Mov     AX, Offset ErrorHandler

;;                XChg    [ES:90h], EAX
; Assuming ES is already set correctly
PUSH AX        ; Save the low word of EAX to the stack
PUSH DX        ; Use DX as a temporary register

; Load the 32-bit memory value into DX:AX
MOV AX, WORD PTR ES:[90h]    ; Load the low word
MOV DX, WORD PTR ES:[92h]    ; Load the high word

; Store the original EAX value (now in DX:AX) into memory
POP WORD PTR ES:[90h]        ; Store the original low word from stack to memory
POP WORD PTR ES:[92h]        ; Store the original high word from stack to memory

; The original EAX is now in DX:AX. To return the value, simply use DX:AX
; The memory location now contains the original value of EAX

;;                Mov     DWord Ptr CS:OldHandlerOffset, EAX
; Assuming OldHandlerOffset is defined as a DWORD in your 32-bit code,
; it corresponds to two consecutive words in 8086 assembly.
; For example:
; OldHandlerOffset DW ?
;                  DW ?

; To store the 32-bit value from EAX, perform two 16-bit moves.

; Move the low 16 bits of EAX (which is AX) to the first word
MOV CS:WORD PTR OldHandlerOffset, AX

; Move the high 16 bits of EAX (from the EDX register after a move or calculation
; in 32-bit code) to the second word
MOV CS:WORD PTR OldHandlerOffset + 2, DX

                Pop     ES
                Ret

EndP            Error_InitHandler

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

Proc            Error_UnInitHandler Far

                Push    ES
                Xor     AX, AX
                Mov     ES, AX

;;                Mov     EAX, DWord Ptr CS:OldHandlerOffset
;;                Mov     [ES:90h], EAX
; Read the 32-bit pointer into a 16-bit register pair (e.g., DX:AX)
MOV AX, WORD PTR CS:OldHandlerOffset        ; Get the offset (lower 16 bits)
MOV DX, WORD PTR CS:[OldHandlerOffset + 2]  ; Get the segment (higher 16 bits)

; Write the 32-bit pointer from the register pair to the destination
MOV WORD PTR ES:[90h], AX                   ; Store the offset
MOV WORD PTR ES:[92h], DX                   ; Store the segment


                Pop     ES
                Ret

EndP            Error_UnInitHandler

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

EndS

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

End
