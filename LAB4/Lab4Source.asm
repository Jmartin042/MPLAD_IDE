;;;;;;; P2 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use 10 MHz crystal frequency.
; Use Timer0 for ten millisecond looptime.
; Blink "Alive" LED every two and a half seconds.
; Display PORTD as a binary number.
; Toggle C2 output every ten milliseconds for measuring looptime precisely.
;
;;;;;;; Program hierarchy ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mainline
;   Initial
;     InitLCD
;       LoopTime
;   BlinkAlive
;   ByteDisplay (DISPLAY macro)
;     DisplayC
;       T40
;     DisplayV
;       T40
;   LoopTime
;
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000                  ;Beginning of Access RAM
        TMR0LCOPY                      ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY                     ;Copy of INTCON for LoopTime subroutine
        COUNT                          ;Counter available as local to subroutines
        ALIVECNT                       ;Counter for blinking "Alive" LED
        BYTE                           ;Eight-bit byte to be displayed
        BYTESTR:10                     ;Display string for binary version of BYTE

		WREG_TEMP
		STATUS_TEMP
		PORTA_TEMP
		ADCON0_TEMP
		TIMECOUNT
        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm

POINT   macro  stringname
        MOVLF  high stringname, TBLPTRH
        MOVLF  low stringname, TBLPTRL
        endm

DISPLAY macro  register
        movff  register,BYTE
        call  ByteDisplay
        endm
;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000                    ;Reset vector
        nop
        goto  Mainline

        org  0x0008                    ;High priority interrupt vector
		goto HPISR                     ;execute High Priority Interrupt Service Routine


        org  0x0018                    ;Low priority interrupt vector
        goto  LPISR                    ;execute Low Priority Interrupt Service Routine

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial                 ;Initialize everything
        ;MAIN LOOP BELOW
L1
         btg  PORTE,RE2               ;Toggle pin, to support measuring loop time
         rcall  LoopTime              ;Make looptime be ten milliseconds
         bra	L1


;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial

		MOVLF  B'00010011',ADCON0
                MOVLF  B'10001110',ADCON1      ;Enable PORTA & PORTE digital I/O pins
		MOVLF  B'01000111',ADCON2

        MOVLF  B'11100001',TRISA       ;Set I/O for PORTA
        MOVLF  B'11011111',TRISB       ;Set I/O for PORTB
		MOVLF  B'11010000',TRISC       ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD       ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE       ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON       ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA       ;Turn off all four LEDs driven from PORTA

		bsf RCON,IPEN 				   ;Enable high/low interrupt structure
		bsf INTCON,GIEH				   ;Enable high-priority interrupts
		bsf INTCON,GIEL				   ;Enable low-priority interrupts
		bsf INTCON2, INTEDG0
		bsf INTCON2, INTEDG1

	        bcf INTCON,INT0IF
		bcf INTCON3, INT1IP

                bsf INTCON3, INT1IE
		bsf INTCON, INT0IE

		bcf INTCON3, INT1IF

		return




;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bignum  equ     65536-250+12+2

LoopTime
		btfss INTCON,TMR0IF            ;Wait until ten milliseconds are up
        bra	LoopTime
		movff  INTCON,INTCONCOPY       ;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY         ;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L         ;Write 16-bit counter at this moment
        movf  INTCONCOPY,W             ;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF             ;Clear Timer0 flag
        return

;;;;;LEDDelay;;;;;;
Delay1ms
	MOVLF 10,TIMECOUNT
DelayLoop
	rcall LoopTime
	decf TIMECOUNT,F
	bnz DelayLoop
	MOVLF 10, TIMECOUNT
	return

;;;;;;; LEDSteps;;;;;;;;;;;;;;;;;;;
LEDSteps
;;;Count up from STEP 1 to STEP 8
	bsf PORTA,RA3
	bsf PORTA,RA2
	bsf PORTA,RA1
	rcall Delay1ms

	bsf PORTA,RA3
	bsf PORTA,RA2
	bcf PORTA,RA1
	rcall Delay1ms

	bsf PORTA,RA3
	bcf PORTA,RA2
	bsf PORTA,RA1
	rcall Delay1ms

	bsf PORTA,RA3
	bcf PORTA,RA2
	bcf PORTA,RA1
	rcall Delay1ms

	bcf PORTA,RA3
	bsf PORTA,RA2
	bsf PORTA,RA1
	rcall Delay1ms

	bcf PORTA,RA3
	bsf PORTA,RA2
	bcf PORTA,RA1
	rcall Delay1ms

	bcf PORTA,RA3
	bcf PORTA,RA2
	bsf PORTA,RA1
	rcall Delay1ms

	bcf PORTA,RA3
	bcf PORTA,RA2
	bcf PORTA,RA1
	rcall Delay1ms

return

;;;;Low Priority Interrupt Service Routine;;;;
LPISR
	movff STATUS, STATUS_TEMP          ; save STATUS and W
	movf W,WREG_TEMP

        bcf PORTE, RE2                     ; Stop pulse train from RE2
	rcall  LEDSteps                    ; Blink the LEDs

	bcf PORTA, RA3
        bcf PORTA, RA2
        bcf PORTA, RA1

	movf WREG_TEMP,W
	movff STATUS_TEMP,STATUS

	bcf INTCON3,INT1IF
	retfie
	return

;;;;High Priority Interrupt Service Routine;;;;
HPISR

		bcf PORTE,RE2                 ;Stop pulse train from RE2

		bcf PORTA,RA3
		bcf PORTA,RA2
		bcf PORTA,RA1

		
HPLoop

                rcall Analog2Dig             ; start Analog to Digital Conversion
		;DISPLAY ADRESH
		movlw B'00000000'
		cpfseq ADRESH
		bra HPLoop	

		bcf INTCON,INT0IF

		retfie FAST


;;;;Analog-to-Digital Conversion Code;;;;
Analog2Dig
	bsf ADCON0,1
	ADCloop
	btfsc ADCON0,1
	bra ADCloop
	return



;;;;;;; Constant strings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCDstr  db  0x33,0x32,0x28,0x01,0x0c,0x06,0x00  ;Initialization string for LCD
CODE1  db  "\x80CODE   \x00"         ;Write "TESTING:" to first line of LCD
UNLOCKED  db  "\xc0UNLOCKED   \x00"
LCDclear1 db "\x80			  \x00"
LCDclear2 db "\xc0			  \x00"

end