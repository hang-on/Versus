; --------------------------------------------------------------
; PREPARE VRAM.
; Set up vdp to recieve data at vram address in HL.
PrepareVRAM:
           push af
           ld a,l
           out ($bf),a
           ld a,h
           or $40
           out ($bf),a
           pop af
           ret

; --------------------------------------------------------------
; LOAD VRAM.
; Load BC amount of bytes from data source pointed to by HL.
; Tip: Prepare VRAM before calling.
LoadVRAM:
           ld a,(hl)
           out ($be),a
           inc hl
           dec bc
           ld a,c
           or b
           jp nz,LoadVRAM
           ret

; --------------------------------------------------------------
; FILL MEMORY.
; Overwrite a chunk of memory with a specified byte value.
; HL = base address, BC = area size, A = fill byte.
FillMemory:
           ld (hl),a
           ld d,h
           ld e,l
           inc de
           dec bc
           ld a,b
           or c
           ret z
           ldir
           ret

; --------------------------------------------------------------
; SET VDP REGISTER.
; Write to target register.
; A = byte to be loaded into vdp register.
; B = target register 0-10.
SetRegister:
           out ($bf),a
           ld a,$80
           or b
           out ($bf),a
           ret

; --------------------------------------------------------------
; GET VECTOR.
; Vector table based switch-like control structure.
; A = expression, DE = vector table (word-sized vectors).
; Return vector in HL for a jp (hl) opcode.
GetVector:
           sla a
           ld h,0
           ld l,a
           add hl,de
           ld a,(hl)
           inc hl
           ld h,(hl)
           ld l,a
           ret

; --------------------------------------------------------------
; WAIT FOR FRAME INTERRUPT.
; This will wait exclusively for the frame interrupt.
; Unlike the 'halt' opcode.
WaitForFrameInterrupt:
           ld a,(FrameInterruptFlag)
           or a
           jp z,WaitForFrameInterrupt
           xor a
           ld (FrameInterruptFlag),a
           ret
