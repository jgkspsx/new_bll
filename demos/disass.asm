;DISASS 65SC02-DISASSMEBLER
;
; created : 200792-
;
;

IMPL	EQU 0
IMM 	EQU 1
REL	EQU 2
ZERO	EQU 3
ZEROX	EQU 4
ZEROY	EQU 5
ABS	EQU 6
ABSX	EQU 7
ABSY	EQU 8
ABSIND	EQU 9
IND	EQU 10
INDX	EQU 11


POINTER	EQU $40	; Zeiger auf MC
MNE_PTR	EQU $42	; Zeiger auf Mnemoniks

DISPAGE:	LDA #$F
	PHA
	JSR DISLINE
	PLA
	DEC
	BPL DISPAGE+2
	RTS

DISLINE:	JSR NEWLINE
	LDA POINTER+1
	JSR HEXOUT
	LDA POINTER
	JSR HEXOUT
	JSR PRINT
	DB ": ",0

	LDA (POINTER)
	AND #$F	; Hi-Byte maskieren
	CMP #1
	BCC BRANCHES2
	BEQ _ORA2
	CMP #3
	BCC _ORA2
	BEQ ILLEGAL
	CMP #5
	BCC _TSB2
	BEQ _ORA2
	CMP #7
	BCC _ASL2
	BEQ ILLEGAL
	CMP #9
	BCC _PHP2
	BEQ _ORA2
	CMP #11
	BCC _INC2
	BEQ ILLEGAL
	CMP #13
	BCC _TSB2
	BEQ _ORA2
	CMP #15
	BCC _ASL2
	BRA ILLEGAL

BRANCHES2	JMP BRANCHES
_ORA2	JMP _ORA
_TSB2	JMP _TSB
_ASL2	JMP _ASL
_PHP2	JMP _PHP
_INC2	JMP _INC

ILLEGAL:	JSR PRINT
	DB "****",0
PLUS1:	LDA #1
	BRA PLUS
PLUS2:	LDA #2
	BRA PLUS
PLUS3	LDA #3
PLUS	TAX
	LDY CURX	; akt. Cursorpos. merken
	LDA #40	; Bildschirmmitte
	STA CURX
DISDUMP	LDA (POINTER)
	JSR HEXOUT
	INC CURX
	INC CURX
	INC POINTER
	BNE *+4
	INC POINTER+1
	DEX
	BNE DISDUMP
	STY CURX
	RTS

BRANCHES:	LDA (POINTER)
	LSR
	LSR
	LSR
	LSR
	LSR
	BCC NO_BRA
	JMP BRANCH

NO_BRA	TAY
	LDX ADR_BRK,Y
	ASL
	ASL
	TAY
	LDA #<MN_BRK
	STA MNE_PTR
	LDA #>MN_BRK
	STA MNE_PTR+1
	JSR PRINTY	; print string (MNE_PTR),Y
	LDY #1
	TXA 	; addressing mode
	BEQ PLUS1
	CMP #IMM
	BNE *+5
	JMP IMMEDIATE

	CMP #REL
	BEQ _BRA
	JMP ABSOLUTE

BRANCH	ASL
	ASL
	TAY
	LDA #<MN_Bcc
	STA MNE_PTR
	LDA #>MN_Bcc
	STA MNE_PTR+1
	JSR PRINTY
	LDY #1

_BRA	LDX #0
	LDA (POINTER),Y
	BPL *+4
	LDX #$FF
	CLC
	ADC #2
	BCC *+3
	INX
	CLC
	ADC POINTER
	PHA
	TXA
	ADC POINTER+1
	JSR HEXOUT
	PLA
	JSR HEXOUT
	JMP PLUS2
;--------------------------------
_PHP:	LDA #<MN_PHP
	STA MNE_PTR
	LDA #>MN_PHP
	STA MNE_PTR+1
	BRA CONT_IMPL

_INC:	LDA #<MN_INC
	STA MNE_PTR
	LDA #>MN_INC
	STA MNE_PTR+1
CONT_IMPL	LDA (POINTER)
	LSR
	LSR
	AND #$FC
	TAY
	JSR PRINTY
	JMP PLUS1
;--- ORA-GRUPPE -----------------
_ORA:	LDA #<MN_ORA
	STA MNE_PTR
	LDA #>MN_ORA
	STA MNE_PTR+1
	LDA (POINTER)
	TAX
	CMP #$89	; BIT ?
	BNE CONT_ORA
	LDY #32
	BRA CONT3_ORA
CONT_ORA	CMP #$A2	; LDX #IMM
	BNE CONT2_ORA
	LDY #36
	LDX #9
	BRA CONT3_ORA

CONT2_ORA	LSR
	LSR
	LSR
	AND #$FC
	TAY
CONT3_ORA	JSR PRINTY	; BEFEHL
	LDY #1
	TXA
	AND #$1F
	CMP #$12
	BNE *+5
	JMP INDIREKT
	LSR
	AND #$FE
	TAX
	JMP (JMPTABLE2,X)
;--- ASL-GRUPPE ----------------
_ASL:	LDA #<MN_ASL
	STA MNE_PTR
	LDA #>MN_ASL
	STA MNE_PTR+1
	LDA (POINTER)
	TAX
	LSR
	LSR
	LSR
	AND #$FC
	TAY
	CPX #$9E	; STZ ?
	BNE CONT_ASL
	LDY #32
	LDX #$7E
CONT_ASL	JSR PRINTY	;MNEMONIC
	LDY #1
	TXA
	LSR
	LSR
	LSR
	AND #%11
	ASL
	CPX #$86
	BCC OK_ASL
	CPX #$BF
	BCC DO_X
OK_ASL:	TAX
	JMP (JMPTABLE3,X)
DO_X:	TAX
	JMP (JMPTABLE4,X)
;---------------------------
_TSB	LDA #<MN_TSB
	STA MNE_PTR
	LDA #>MN_TSB
	STA MNE_PTR+1

	LDA (POINTER)
	LSR
	LSR
	LSR	; /8
	TAX
	LDY _TSB_TABLE,X
	LDA _TSB_ADR,X
	BNE *+5
	JMP ILLEGAL
	JSR PRINTY
	LDY #1
	ASL
	TAX
	JMP (JMPTABLE,X)

;---------------------------
PRINTY:	PHA
	PHX
	PHY
	LDX #4
PRINTY0	LDA (MNE_PTR),Y
	JSR CHAROUT
          	INY
	DEX
	BNE PRINTY0
PRINTY2	PLY
	PLX
	PLA
	RTS

;------------------------------

INDIREKT:	LDA #"("
	JSR CHAROUT
	LDA (POINTER),Y
	JSR HEXOUT
	LDA #")"
	JSR CHAROUT
	JMP PLUS2

INDABS:	LDA #"("
	JSR CHAROUT
	LDA (POINTER),Y
	PHA
	INY
	LDA (POINTER),Y
	JSR HEXOUT
	PLA
	JSR HEXOUT
	LDA #")"
	JSR CHAROUT
	JMP PLUS3

INDIREKTX:	LDA #"("
	JSR CHAROUT
	LDA (POINTER),Y
	JSR HEXOUT
	JSR PRINT
	DB ",X)",0
	JMP PLUS2

INDIREKTY:	LDA #"("
	JSR CHAROUT
	LDA (POINTER),Y
	JSR HEXOUT
	JSR PRINT
	DB "),Y",0
	JMP PLUS2

IMMEDIATE: 	LDA #"#"
	JSR CHAROUT
	LDY #1
	LDA (POINTER),Y
	JSR HEXOUT
	JMP PLUS2
ABSOLUTE: 	INY
	LDA (POINTER),Y
	JSR HEXOUT
	DEY
	LDA (POINTER),Y
	JSR HEXOUT
	JMP PLUS3

ABSOLUTEX 	JSR ABSOLUTE
	JSR PRINT
INDEX	DB ",X",0
	RTS

ABSOLUTEY 	JSR ABSOLUTE
	JSR PRINT
	DB ",Y",0
	RTS

ZEROP	LDA (POINTER),Y
	JSR HEXOUT
	JMP PLUS2

ZEROPX	JSR ZEROP
	JSR PRINT
	DB ",X",0
	RTS

ZEROPY	JSR ZEROP
	JSR PRINT
	DB ",Y",0
	RTS

;---------------------------

_TSB_TABLE 	DB 0,0,4,4,8,8,8,8,36,32,36,0,12,32,12,32
	DB 16,16,16,12,20,20,20,20,24,24,0,0,28,28,0,0

_TSB_ADR	DB ZERO,ABS,ZERO,ABS,ZERO,ABS,ZEROX,ABSX,ZERO,ABS,ZEROX,0
	DB ZERO,ABSIND,ZEROX,INDX,ZERO,ABS,ZEROX,ABS,ZERO,ABS
	DB ZEROX,ABSX,ZERO,ABS,0,0,ZERO,ABS,0,0
;	    0    4   8   12 16   20 24  28  32
MN_TSB	DB "TSB TRB BIT STZ STY LDY CPY CPX JMP ??? "

MN_BRK	DB "BRK JSR RTI RTS BRA LDY CPY CPX "
ADR_BRK	DB IMM,ABS,IMPL,IMPL,REL,IMM,IMM,IMM

MN_Bcc	db "BPL BMI BVC BVS BCC BCS BNE BEQ "

MN_PHP	DB "PHP CLC PLP SEC PHA CLI PLA SEI "
	DB "DEY TYA TAY CLV INY CLD INX SED "
MN_INC	DB "ASL INC ROL DEC LSR PHY ROR PLY "
	DB "TXA TXS TAX TSX DEX PHX NOP PLX "
MN_ORA	DB "ORA AND EOR ADC STA LDA CMP SBC BIT LDX "
MN_ASL	DB "ASL ROL LSR ROR STX LDX DEC INC STZ "

JMPTABLE 	DW 0,0,0,ZEROP,ZEROPX,ZEROPY,ABSOLUTE,ABSOLUTEX
	DW ABSOLUTEY,INDABS,INDIREKT,INDIREKTX
JMPTABLE2 	DW INDIREKTX,ZEROP,IMMEDIATE,ABSOLUTE
	DW INDIREKTY,ZEROPX,ABSOLUTEY,ABSOLUTEX
JMPTABLE3	DW ZEROP,ABSOLUTE,ZEROPX,ABSOLUTEX
JMPTABLE4	DW ZEROP,ABSOLUTE,ZEROPY,ABSOLUTEY

	END
;** 65C02-BEFEHLE
_BBR2:	LDA (POINTER)
	BMI IS_BBS
	JSR PRINT
	DB "BBR",0
	BRA CONT_BBR
IS_BBS	JSR PRINT
	DB "BBS",0
CONT_BBR:	LSR
	LSR
	LSR
	LSR
	AND #7
	CLC
	ADC #"0"
	JSR CHAROUT
	LDA #" "
	JSR CHAROUT
	LDY #1
	BRA _BRA
_RMB2	LDA (POINTER)
	BMI IS_SMB
	JSR PRINT
	DB "RMB",0
	BRA CONT_RMB
IS_SMB	JSR PRINT
	DB "SMB",0
CONT_RMB	LSR
	LSR
	LSR
	LSR
	AND #$7
	CLC
	ADC #"0"
	JSR CHAROUT
	LDA #" "
	JSR CHAROUT
	LDY #1
	LDA (POINTER),Y
	JSR HEXOUT
	JMP PLUS2
	END
