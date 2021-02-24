;;;;;;; P5 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use this template for Experiment 5
; This file was created by AC on 3/31/2020
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

        cblock  0x000           ;Beginning of Access RAM
		; --- BEGIN variables for TABLAT POINTER
		; DO NOT MODIFY (created by AC) 
		value
		counter
		; --- END variables for TABLAT POINTER

		; Create your variables starting from here

		ProgMem

		valueH
		
		xn1
		xn2
		xn3
		xn4
		xn5
		xn6
		xn7
		xn8
		xn9

		SUMH
		SUML
		
		SUM2H
		SUM2L

		TEMP
		TEMPH

		ResL
		ResH	

        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm


;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000             ;Reset vector
        nop
        goto  Mainline

        org  0x0008             ;High priority interrupt vector
        goto  $  ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto  $                  ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial          ;Initialize everything
Loop
	
		; --------------------------------------------------------------
		; Change value for counter depending 
		; on period of time series that you wish to use
		;
		MOVLF  8,counter
		MOVLF upper SimpleTable,TBLPTRU 
		MOVLF high  SimpleTable,TBLPTRH 
		MOVLF low   SimpleTable,TBLPTRL
		
		; --------------------------------------------------------------
		; BEGIN WRTING CODE HERE 

	label_A
		
		movff xn8, xn9		;xn9 = xn8 (xn9=x[n-9], xn8=x[n-8],...)
		movff xn7, xn8		;xn8 = xn7
		movff xn6, xn7		;xn7 = xn6
		movff xn5, xn6		;xn6 = xn5	
		movff xn4, xn5		;xn5 = xn4
		movff xn3, xn4		;xn4 = xn3
		movff xn2, xn3		;xn3 = xn2
		movff xn1, xn2		;xn2 = xn1
		movff value, xn1	;xn1 = value
		
		TBLRD*+
		movf TABLAT, W
		movwf value ; value = TABLAT (current value of the program memory)

		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;First Summation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		movf xn3, W ; changes wreg to xn3
		
		addwf value,W ; x[n]+x[n-3]=SUML
		movwf SUML ;result into SUML
		
		movf TEMPH,W

		addwfc valueH,w ;x[n]+x[n-3]=SUMH with bit carry
		movwf SUMH ;result into SUMH
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Second Summation;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		movf xn6,W ;changes wreg to xn6
		
		addwf xn9,W ; x[n-6]+x[n-9]=SUM2L
		movwf SUM2L ;result into SUM2L
		
		movf TEMPH,W

		addwfc valueH,w ;x[n-6]+x[n-9]=SUM2H with bit carry
		movwf SUM2H ;result into SUM2H
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Final Summation;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		movf SUML,W
		
		addwf SUM2L,W ; SUML+SUM2L=SUM2L
		movwf SUM2L ;result into SUM2L
		
		movf SUMH,W

		addwfc SUM2H,w  ; SUMH+SUM2H=SUM2H
		movwf SUM2H ;result into SUM2H
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Division by 4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		rrcf SUM2H, W ;rotate to the right for both high and low, for division by 2
		movwf SUM2H

		rrcf SUM2L, W
		movwf SUM2L
		
		rrcf SUM2H, W ;2nd rotate is performed for both high and low, this produces
		movwf SUM2H   ;an overall division by 4
		
		rrcf SUM2L, W
		movwf SUM2L
		
		;;;;;;;;;;;;;;;;;;;;;;Final Result;;;;;;;;;;;;;;;;;;;;;

		movff SUM2L, ResL ;copy final result into ResL and ResH
		movff SUM2H, ResH

		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


		; FINISH WRTING CODE HERE 
		; --------------------------------------------------------------

		decf  counter,F        
	    bz  label_B
		bra label_A
	label_B

        bra	Loop
	



;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
        MOVLF  B'10001110',ADCON1  ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA  ;Set I/O for PORTA 0 = output, 1 = input
        MOVLF  B'11011100',TRISB  ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC  ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD  ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE  ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON  ;Set up Timer0 for a looptime of 10 ms;  bit7=1 enables timer; bit3=1 bypass prescaler
        MOVLF  B'00010000',PORTA  ;Turn off all four LEDs driven from PORTA ; See pin diagrams of Page 5 in DataSheet
       
		
		MOVLF  B'00000000',ProgMem 

		MOVLF  B'00000000',value
		MOVLF  B'00000000',valueH
		MOVLF  B'00000000',xn1
		MOVLF  B'00000000',xn2
		MOVLF  B'00000000',xn3
		MOVLF  B'00000000',xn4
		MOVLF  B'00000000',xn5
		MOVLF  B'00000000',xn6
		MOVLF  B'00000000',xn7
		MOVLF  B'00000000',xn8
		MOVLF  B'00000000',xn9
				
		MOVLF B'00000000',SUML
		MOVLF B'00000000',SUMH
		
		MOVLF B'00000000',SUM2L
		MOVLF B'00000000',SUM2H

		MOVLF  B'00000000',TEMP
		MOVLF  B'00000000',TEMPH
		
		MOVLF B'00000000',ResL
		MOVLF B'00000000',ResH

		return



;;;;;;; TIME SERIES DATA
;
; 	The following bytes are stored in program memory.
;   Created by AC 
;	
;  Choose your Periodic Sequence
;--------------------------------------------------------------
; time series X1
;SimpleTable ; ---> period 2
;db 180,240
;--------------------------------------------------------------
; time series X2
;SimpleTable ; ---> period 4
;db 180,240,200,244
;--------------------------------------------------------------
; time series X3
;SimpleTable ; ---> period 6
;db 180,240,200,244,216,236
;--------------------------------------------------------------
; time series X4
SimpleTable ; ---> period 8
db 180,240,200,244,216,236,160,176
; --------------------------------------------------------------

        end

